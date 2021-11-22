local utils = require('agitator.utils')

local function pick_file_from_branch(branch)
    local pickers = require "telescope.pickers"
    local finders = require "telescope.finders"
    local conf = require("telescope.config").values
    local actions = require "telescope.actions"
    local action_state = require "telescope.actions.state"
    local opts = {}
    local relative_fname = utils.get_relative_fname()
    opts.initial_model = 'insert'
    pickers.new(opts, {
        prompt_title = "filename",
        finder = finders.new_oneshot_job { "git", "ls-tree", "-r", "--name-only", branch, opts },
        sorter = conf.generic_sorter(opts),
        attach_mappings = function(prompt_bufnr, map)
            actions.select_default:replace(function()
                actions.close(prompt_bufnr)
                local selection = action_state.get_selected_entry()
                -- open fugitive for that branch and filename
                -- vim.cmd('Gedit ' .. branch .. ':' .. selection[1])
                vim.api.nvim_command('new')
                utils.open_file_branch(branch, selection[1])
            end)
            return true
        end,
    }):find()
    -- the file picker is not insert mode.. possibly it's reusing the picker
    -- from the previous branch picker... switch to insert mode (i), then
    -- enter the current filename. Couldn't find how to set the picker default
    -- entry text otherwise -- did ask on the telescope gitter, no answer.
    vim.fn.feedkeys('i' .. relative_fname)
end

local function open_file_git_branch()
    -- https://github.com/nvim-telescope/telescope.nvim/blob/master/lua/telescope/builtin/git.lua#L269
    local pickers = require "telescope.pickers"
    local finders = require "telescope.finders"
    local conf = require("telescope.config").values
    local actions = require "telescope.actions"
    local action_state = require "telescope.actions.state"
    local opts = {}

    pickers.new(opts, {
        prompt_title = "branch",
        finder = finders.new_oneshot_job { "git", "branch", opts },
        sorter = conf.generic_sorter(opts),
        attach_mappings = function(prompt_bufnr, map)
          actions.select_default:replace(function()
            actions.close(prompt_bufnr)
            local selection = action_state.get_selected_entry()
            local branch = selection[1]:sub(3)
            pick_file_from_branch(branch)
          end)
          return true
        end,
    }):find()
end

return {
    open_file_git_branch = open_file_git_branch
}
