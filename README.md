# relative-numbers package

![Example Screencast](https://github.com/justmoon/relative-numbers/blob/master/screencast.gif?raw=true)

Replaces the regular line numbers with relative numbers. Shows the current line number on the active line.

## Supports vim-mode

In [vim-mode](https://github.com/atom/vim-mode)'s insert mode, line numbers will automatically revert back to absolute.

## Customization

### Change current line color

To change the color for the currently highlighted line, put the following in your stylesheet.

``` less
atom-text-editor.editor .line-numbers .relative.current-line {
  color: purple
}
```
