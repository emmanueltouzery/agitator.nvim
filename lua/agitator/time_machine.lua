local Str = require'plenary.strings'
local utils = require('agitator.utils')

local function force_length(msg, len)
    if Str.strdisplaywidth(msg) > len then
        return Str.truncate(msg, len)
    else
        return Str.align_str(msg, len, false)
    end
end

local function statusline_escape(msg)
    return msg:gsub(' ', '\\ '):gsub('"', '\\"')
end

local function time_machine_statusline(i, entries_count, record)
    vim.api.nvim_command('set laststatus=2')
    vim.api.nvim_command('set statusline=')
    vim.api.nvim_command('set statusline+=%#StatusLineNC#')
    vim.api.nvim_command('set statusline+=['  .. (entries_count + 1 - i) .. '\\/' .. entries_count .. ']')
    vim.api.nvim_command('set statusline+=%#Title#')
    vim.api.nvim_command('set statusline+=\\ ' .. statusline_escape(force_length(record.author, 18)))
    vim.api.nvim_command('set statusline+=\\ ')
    vim.api.nvim_command('set statusline+=%#TabLineSel#')
    vim.api.nvim_command('set statusline+=' .. statusline_escape(force_length(record.message, 50)))
    vim.api.nvim_command('set statusline+=%#TabLine#')
    vim.api.nvim_command('set statusline+=\\ ' .. record.date:gsub(' ', '\\ ') .. '\\ ')
    vim.api.nvim_command('set statusline+=%#StatusLineNC#')
    vim.api.nvim_command('set statusline+=<c-p>\\ Previous\\ \\|\\ <c-n>\\ Next\\ \\|\\ <c-y>\\ Copy\\ commit\\ SHA\\ \\|\\ [q]uit')
    vim.api.nvim_command('set statusline+=%<') -- please truncate at the end
end

local function git_time_machine_display()
    local i = vim.b.time_machine_cur_idx
    local commit_sha = vim.b.time_machine_entries[i].sha
    local save_pos = vim.fn.getpos(".")
    -- clear buffer
    vim.api.nvim_command('%delete')
    utils.open_file_branch(commit_sha, vim.b.time_machine_rel_fname)
    vim.fn.setpos('.', save_pos)
    local record = vim.b.time_machine_entries[i]
    local entries_count = #vim.b.time_machine_entries
    vim.defer_fn(function() time_machine_statusline(i, entries_count, record) end, 50)
end

local function git_time_machine_next()
    if vim.b.time_machine_cur_idx > 1 then
        vim.b.time_machine_cur_idx = vim.b.time_machine_cur_idx - 1
    end
    git_time_machine_display()
end

local function git_time_machine_previous()
    if vim.b.time_machine_cur_idx < #vim.b.time_machine_entries then
        vim.b.time_machine_cur_idx = vim.b.time_machine_cur_idx + 1
    end
    git_time_machine_display()
end

local function parse_time_machine_record(lines, i)
    if lines[i]:sub(1, 7) ~= "commit " then
        error("Expected 'commit', got " .. lines[i])
    end
    local record = {}
    record.sha = lines[i]:sub(8)
    i = i + 1
    record.author = lines[i]:sub(9):gsub(' <.*$', '')
    i = i + 1
    record.date = lines[i]:sub(9, 24)
    i = i + 2
    record.message = lines[i]:sub(5)
    while i <= #lines and lines[i]:sub(1, 7) ~= 'commit ' do
        i = i + 1
    end
    return i, record
end

local function handle_time_machine(lines)
    local i = 1
    local results = {}
    while lines[i] do
        i, line_info = parse_time_machine_record(lines, i)
        table.insert(results, line_info)
    end
    vim.b.time_machine_entries = results
    vim.b.time_machine_cur_idx = 1
    git_time_machine_next()
end

-- 'git log --no-merges -- afc/pom.xml'
local function git_time_machine()
    local relative_fname = utils.get_relative_fname()
    vim.api.nvim_command('new')
    vim.api.nvim_command('nnoremap <buffer> <c-p> :lua require"agitator".git_time_machine_previous()<CR>')
    vim.api.nvim_command('nnoremap <buffer> <c-n> :lua require"agitator".git_time_machine_next()<CR>')
    vim.api.nvim_command('nnoremap <buffer> <c-y> :lua require"agitator".git_time_machine_copy_sha()<CR>')
    vim.api.nvim_command('nnoremap <buffer> q :lua require"agitator".git_time_machine_quit()<CR>')
    vim.b.time_machine_rel_fname = relative_fname
    local Job = require'plenary.job'
    local output = {}
    Job:new {
        command = 'git',
        -- i'd really want a plumbing command here, but i think there isn't one
        -- https://stackoverflow.com/a/29239964/516188
        args = {'log', '--no-merges', '--follow', '--date=iso', '--', relative_fname},
        on_stdout = function(error, data, self)
            table.insert(output, data)
        end,
        on_exit = function(self, code, signal)
            vim.schedule_wrap(function()
                handle_time_machine(output)
            end)()
        end
    }:start()
end

return {
    git_time_machine = git_time_machine,
    git_time_machine_next = git_time_machine_next,
    git_time_machine_previous = git_time_machine_previous,
    git_time_machine_copy_sha = git_time_machine_copy_sha,
    git_time_machine_quit = git_time_machine_quit
}
