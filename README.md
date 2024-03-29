# agitator.nvim

agitator is a neovim/lua plugin providing some git-related functions:

## blame

![blame screenshot](https://raw.githubusercontent.com/wiki/emmanueltouzery/agitator.nvim/blame.png)

Blame adds a window on the left side of your window with blame information for the file.
The sidebar is scroll bound to the main file window.
Three functions are exported:

- `git_blame({sidebar_width?, formatter?})`: open the sidebar. The default width is 30 characters, you
  can optionally pass another width in a record, eg `{sidebar_width = 20}`. You can also pass in a
  formatter function, to display the commit information, see lower;
- `git_blame_close()`: close the blame sidebar;
- `git_blame_toggle()`: toggle (open or close) the blame sidebar.
- `git_blame_commit_for_line()`: get the git commit SHA for the current line, as string.

This last function, to get the commit SHA, can allow to display the commit for a certain line of code.
However you'll need an external plugin to display the commit, such as [neogit](https://github.com/TimUntersberger/neogit)
or [diffview.nvim](https://github.com/sindrets/diffview.nvim/).
Here is an example of integration with diffview:

```lua
function _G.ShowCommitAtLine()
    local commit_sha = require"agitator".git_blame_commit_for_line()
    vim.cmd("DiffviewOpen " .. commit_sha .. "^.." .. commit_sha)
end
```

The formatter function for `git_blame()` lets you customize the rendering of the blame information.
For instance, you could call:

```lua
require'agitator'.git_blame{formatter=function(r) return r.author .. " => " .. r.summary; end}
```

And you'd get in a sidebar the author and the commit summary instead of the author and date, which is
the default.
The formatter function receives a single parameter, which has the following fields:

- author
- summary
- date, which is a `os.date` which has among others `year` `month` and `day` fields.

## git find file

Git find file will open two telescope pickers in succession. The first one to
pick a git branch; the second one to pick a file from that branch.
The selected file from another branch is then displayed in a read-only buffer.

- `open_file_git_branch()`

## search in git branch

search git branch will open two telescope pickers in succession. The first one to
pick a git branch; the second one to enter text to search for in that branch.
The selected file from another branch is then displayed in a read-only buffer.

- `search_git_branch()`

## search in added lines

search in added will open a telescope picker to search in lines that you've
added compared to your git checkout: basically you search in the git diff.

- `search_in_added()`

## time machine

![time machine screenshot](https://raw.githubusercontent.com/wiki/emmanueltouzery/agitator.nvim/time-machine.png)

The time machine allows you to see the history of a single file through time.
It opens a new read-only window, where you can navigate through
past versions of the file and view their contents.
Details about the currently displayed version appear in a popup window at the bottom-right.

- `git_time_machine({use_current_win?, set_custom_shortcuts?, popup_last_line?, popup_width?})`

You can pass in `{use_current_win: true}` to reuse the current window instead of creating a new one.

`set_custom_shortcuts` allows to customize the shortcuts for the time machine.
It should be a function, that'll receive the buffer number of the time machine.
You should set up the autocommands you want; you can reproduce the default behavior with this implementation:

```lua
{
  set_custom_shortcuts = function(code_bufnr)
    vim.keymap.set('n', '<c-p>', function()
      require"agitator".git_time_machine_previous()
    end, {buffer = code_bufnr})
    vim.keymap.set('n', '<c-n>', function()
      require"agitator".git_time_machine_next()
    end, {buffer = code_bufnr})
    vim.keymap.set('n', '<c-h>', function()
      require"agitator".git_time_machine_copy_sha()
    end, {buffer = code_bufnr})
    vim.keymap.set('n', 'q', function()
      require"agitator".git_time_machine_quit()
    end, {buffer = code_bufnr})
  end
}
```

If you change the shortcuts for instance, you'd probably want to change the shortcut hints at the bottom
of the popup window. You can do that with the `popup_last_line` option. You can reproduce the default
behavior with this implementation:

```lua
{ popup_last_line = '<c-p> Previous | <c-n> Next | <c-h> Copy SHA | [q]uit' }
```

You can also change the popup width with `popup_width`. The default value is currently 53.

## General

To call any function, if you use a plugin manager such as Packer, you must
prepend `require('agitator')`. For instance `require('agitator').git_blame()`.

I'm really a beginner in nvim/lua, so don't be surprised if some things are
strangely or wrongly implemented. There are also a couple of ugly hacks. Pull
requests are welcome. I'll do my best to fix bugs, but don't expect too much.

This plugin has two dependencies: [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim/)
and [plenary.nvim](https://github.com/nvim-lua/plenary.nvim).

The plugin is meant to be combined with [gitsigns](https://github.com/lewis6991/gitsigns.nvim),
[neogit](https://github.com/TimUntersberger/neogit) and [diffview](https://github.com/sindrets/diffview.nvim),
so I won't add features covered by these.
