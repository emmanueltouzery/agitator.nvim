local pickers = require "telescope.pickers"
local finders = require "telescope.finders"
local conf = require("telescope.config").values
local action_state = require "telescope.actions.state"
local action_set = require('telescope.actions.set')
local make_entry = require "telescope.make_entry"
local entry_display = require "telescope.pickers.entry_display"

local function search_in_added_add_untracked(lines_with_numbers, opts)
    vim.fn.jobstart("git ls-files --full-name :/ --exclude-standard --others", {
        stdout_buffered = true,
        on_stdout = vim.schedule_wrap(function(j, output)
            for _, untracked_fname in ipairs(output) do
                if untracked_fname ~= "" then
                    local path = vim.fs.root(0, ".git") .. "/" .. untracked_fname
                    local stat = vim.uv.fs_lstat(path)
                    if stat ~= nil and stat.type ~= "link" then
                        local contents = vim.fn.readfile(path)
                        local cur_line = 1
                        for _, line in ipairs(contents) do
                            table.insert(lines_with_numbers, vim.fs.root(0, ".git") .. "/" .. untracked_fname .. ":" .. cur_line .. ":" .. 1 .. ":" .. line)
                            cur_line = cur_line + 1
                        end
                    end
                end
            end
        end),
        on_exit = vim.schedule_wrap(function(j, output)
            pickers
            .new(opts, {
                prompt_title = "Search in git added compared to " .. (opts.git_rev or "HEAD"),
                finder = finders.new_table {
                    results = lines_with_numbers,
                    entry_maker = make_entry.gen_from_vimgrep(opts),
                },
                sorter = conf.generic_sorter(opts),
                previewer = conf.grep_previewer(opts),
            })
            :find()
        end)
    })
end

local function search_in_added(opts)
    local opts = opts or {}
    local lines_with_numbers = {}
    local cur_file = nil
    local cur_line = nil
    vim.fn.jobstart("git diff -U0 " .. (opts.git_rev or "HEAD"), {
        on_stdout = vim.schedule_wrap(function(j, output)
            for _, line in ipairs(output) do
                if string.match(line, "^%+%+%+") then
                    -- new file
                    cur_file = string.sub(line, 6, -1)
                elseif string.match(line, "^@@ -") then
                    -- hunk
                    cur_line = tonumber(string.gmatch(line, "%+(%d+)")())
                elseif string.match(line, "^%+") then
                    -- added line
                    table.insert(lines_with_numbers, vim.fs.root(0, ".git") .. "/" .. cur_file .. ":" .. cur_line .. ":" .. 1 .. ":" .. string.sub(line, 2, -1))
                    cur_line = cur_line + 1
                end
            end
        end),
        on_exit = vim.schedule_wrap(function(j, output)
            search_in_added_add_untracked(lines_with_numbers, opts)
        end)
    })
end

return {
    search_in_added = search_in_added,
}
