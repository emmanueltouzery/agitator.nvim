# agitator.nvim

agitator is a neovim/lua plugin providing some git-related functions:

## blame

![blame screenshot](https://raw.githubusercontent.com/wiki/emmanueltouzery/agitator.nvim/blame.png)

Blame adds a window on the left side of your window with blame information for the file.
The sidebar is scroll bound to the main file window.
Three functions are exported:

* `git_blame({sidebar_width?})`: open the sidebar. The default width is 30 characters, you
  can optionally pass another width in a record, eg `{sidebar_width = 20}`;
* `git_blame_close()`: close the blame sidebar;
* `git_blame_toggle()`: toggle (open or close) the blame sidebar.

## git find file

Git find file will open two telescope pickers in succession. The first one to
pick a git branch; the second one to pick a file from that branch.
The selected file from another branch is then displayed in a read-only buffer.

* `open_file_git_branch()`

## time machine

The time machine allows you to see the history of a single file through time.
It opens a new read-only window, where you can navigate through
past versions of the file and view their contents.
Details about the currently displayed version appear in the vim statusline.

* `git_time_machine()`

## General

I'm really a beginner in nvim/lua, so don't be surprised if some things are
strangely or wrongly implemented. There are also a couple of ugly hacks. Pull
requests are welcome. I'll do my best to fix bugs, but don't expect too much.

This plugin has two dependencies: [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim/)
and [plenary.nvim](https://github.com/nvim-lua/plenary.nvim).

The plugin is meant to be combined with [gitsigns](https://github.com/lewis6991/gitsigns.nvim),
[neogit](https://github.com/TimUntersberger/neogit) and [diffview](https://github.com/sindrets/diffview.nvim),
so I won't add features covered by these.