{CompositeDisposable} = require 'atom'

module.exports =
class LineNumberView
  constructor: (@editor) ->
    @subscriptions = new CompositeDisposable()
    @editorView = atom.views.getView(@editor)
    @trueNumberCurrentLine = atom.config.get('relative-numbers.trueNumberCurrentLine')
    @showAbsoluteNumbers = atom.config.get('relative-numbers.showAbsoluteNumbers')
    @startAtOne = atom.config.get('relative-numbers.startAtOne')

    @lineNumberGutterView = atom.views.getView(@editor.gutterWithName('line-number'))

    @gutter = @editor.addGutter
      name: 'relative-numbers'
    @gutter.view = this

    try
      # Preferred: Subscribe to any editor model changes
      @subscriptions.add @editorView.model.onDidChange(@_update)
    catch
      # Fallback: Subscribe to initialization and editor changes
      @subscriptions.add @editorView.onDidAttach(@_update)
      @subscriptions.add @editor.onDidStopChanging(@_update)

    # Subscribe for when the cursor position changes
    @subscriptions.add @editor.onDidChangeCursorPosition(@_update)

    # Update when scrolling
    @subscriptions.add @editorView.onDidChangeScrollTop(@_update)

    # Subscribe to when the true number on current line config is modified.
    @subscriptions.add atom.config.onDidChange 'relative-numbers.trueNumberCurrentLine', =>
      @trueNumberCurrentLine = atom.config.get('relative-numbers.trueNumberCurrentLine')
      @_update()

    # Subscribe to when the show absolute numbers setting has changed
    @subscriptions.add atom.config.onDidChange 'relative-numbers.showAbsoluteNumbers', =>
      @showAbsoluteNumbers = atom.config.get('relative-numbers.showAbsoluteNumbers')
      @_updateAbsoluteNumbers()

    # Subscribe to when the start at one config option is modified
    @subscriptions.add atom.config.onDidChange 'relative-numbers.startAtOne', =>
      @startAtOne = atom.config.get('relative-numbers.startAtOne')
      @_update()

    # Dispose the subscriptions when the editor is destroyed.
    @subscriptions.add @editor.onDidDestroy =>
      @subscriptions.dispose()

    @_update()
    @_updateAbsoluteNumbers()

  destroy: () ->
    @subscriptions.dispose()
    @_undo()
    @gutter.destroy()

  _spacer: (totalLines, currentIndex) ->
    width = Math.max(0, totalLines.toString().length - currentIndex.toString().length)
    Array(width + 1).join '&nbsp;'

  # Toggle the show-absolute class from the line number gutter view
  _toggleAbsoluteClass: (isActive=false) ->
    classNames = @lineNumberGutterView.className.split(' ')

    # Add the show-absolute class if the setting is active and the class
    # was not previously added
    if isActive
      classNames.push('show-absolute')
      @lineNumberGutterView.className = classNames.join(' ')
    # Remove the show-absolute class if the settings is not active and is in
    # the list of active classNames on the view.
    else
      classNames = classNames.filter((name) -> name != 'show-absolute')
      @lineNumberGutterView.className = classNames.join(' ')

  # Update the line numbers on the editor
  _update: () =>
    # If the gutter is updated asynchronously, we need to do the same thing
    # otherwise our changes will just get reverted back.
    if @editorView.isUpdatedSynchronously()
      @_updateSync()
    else
      atom.views.updateDocument () => @_updateSync()

  _updateSync: () =>
    totalLines = @editor.getLineCount()
    bufferRow = @editor.getCursorBufferPosition().row

    # Check if selection ends with newline (line-selection)
    if @editor.getSelectedText().match /\n$/
      selectRange = @editor.getSelectedBufferRange()
      currentLineNumber = bufferRow

      # Check if multiple line selection
      if selectRange.start.row != selectRange.end.row

        # Check if cursor on first or last line (needed for vim-mode line selection)
        if selectRange.start.row == bufferRow
          currentLineNumber = bufferRow + 1
    else
      currentLineNumber = bufferRow + 1

    lineNumberElements = @editorView.rootElement?.querySelectorAll('.line-number')
    offset = if @startAtOne then 1 else 0

    for lineNumberElement in lineNumberElements
      row = Number(lineNumberElement.getAttribute('data-buffer-row'))
      absolute = row + 1
      relative = Math.abs(currentLineNumber - absolute)
      relativeClass = 'relative'
      if @trueNumberCurrentLine and relative == 0
        relative = currentLineNumber
        relative-- if @startAtOne
        relativeClass += ' current-line'
      # Apply offset last thing before rendering
      relative += offset
      absoluteText = @_spacer(totalLines, absolute) + absolute
      relativeText = @_spacer(totalLines, relative) + relative

      # Keep soft-wrapped lines indicator
      if lineNumberElement.innerHTML.indexOf('•') == -1
        lineNumberElement.innerHTML = "<span class=\"absolute\">#{absoluteText}</span><span class=\"#{relativeClass}\">#{relativeText}</span><div class=\"icon-right\"></div>"

  _updateAbsoluteNumbers: () =>
    className = @lineNumberGutterView.className
    if not className.includes('show-absolute') and @showAbsoluteNumbers
      @_toggleAbsoluteClass(true)
    else if className.includes('show-absolute') and not @showAbsoluteNumbers
      @_toggleAbsoluteClass(false)

  # Undo changes to DOM
  _undo: () =>
    totalLines = @editor.getLineCount()
    lineNumberElements = @editorView.rootElement?.querySelectorAll('.line-number')
    for lineNumberElement in lineNumberElements
      row = Number(lineNumberElement.getAttribute('data-buffer-row'))
      absolute = row + 1
      absoluteText = @_spacer(totalLines, absolute) + absolute
      if lineNumberElement.innerHTML.indexOf('•') == -1
        lineNumberElement.innerHTML = "#{absoluteText}<div class=\"icon-right\"></div>"

    # Remove show-absolute class name if present
    if @lineNumberGutterView.className.includes('show-absolute')
      @_toggleAbsoluteClass(false)
