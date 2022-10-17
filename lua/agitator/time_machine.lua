local Str = require'plenary.strings'
local utils = require('agitator.utils')

local function force_length(msg, len)
    if Str.strdisplaywidth(msg) > len then
        return Str.truncate(msg, len)
    else
        return Str.align_str(msg, len, false)
    end
end

local function time_machine_statusline(i, entries_count, record)
    if vim.b.width ~= vim.fn.winwidth(0) or vim.b.height ~= vim.fn.winheight(0) then
        -- the window was resized, destroy & re-create the popup
        -- to reposition it
        if vim.api.nvim_win_is_valid(vim.b.popup_win) then
            vim.api.nvim_win_close(vim.b.popup_win, true)
        end
        if vim.api.nvim_buf_is_valid(vim.b.popup_buf) then
            vim.api.nvim_buf_delete(vim.b.popup_buf, {force=true})
        end
        setup_timemachine_popup()
    end

    local lines = {
        force_length(record.author, 53), 
        force_length(record.message, 53), 
        record.date .. " - " .. (entries_count - i + 1) .. "/" .. entries_count,
        '<c-p> Previous | <c-n> Next | <c-h> Copy SHA | [q]uit'
    }
    vim.api.nvim_buf_set_lines(vim.b.popup_buf, 0, -1, false, lines)

    vim.api.nvim_buf_add_highlight(vim.b.popup_buf, -1, "Identifier", 0, 0, -1);
    vim.api.nvim_buf_add_highlight(vim.b.popup_buf, -1, "PreProc", 1, 0, -1);
    vim.api.nvim_buf_add_highlight(vim.b.popup_buf, -1, "Special", 2, 0, -1);
    vim.api.nvim_buf_add_highlight(vim.b.popup_buf, -1, "SpecialComment", 3, 0, -1);
end

local function git_time_machine_display()
    local i = vim.b.time_machine_cur_idx
    local commit_sha = vim.b.time_machine_entries[i].sha
    local save_pos = vim.fn.getpos(".")
    -- clear buffer
    vim.bo.readonly = false
    vim.bo.modifiable = true
    vim.api.nvim_command('%delete')
    local complete_fname = utils.git_root_folder() .. '/' .. vim.b.time_machine_entries[i].filename
    local relative_fname = complete_fname:gsub(escape_pattern(vim.fn.getcwd()) .. '/', '')
    utils.open_file_branch(commit_sha, relative_fname)
    if vim.b.time_machine_init_line_no ~= nil then
        -- one-time only: restore the line number from the original buffer
        vim.cmd(':' .. vim.b.time_machine_init_line_no)
        vim.b.time_machine_init_line_no = nil
    else
        vim.fn.setpos('.', save_pos)
    end
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

local function git_time_machine_quit()
    if vim.api.nvim_win_is_valid(vim.b.popup_win) then
        vim.api.nvim_win_close(vim.b.popup_win, true)
    end
    if vim.api.nvim_buf_is_valid(vim.b.popup_buf) then
        vim.api.nvim_buf_delete(vim.b.popup_buf, {force=true})
    end
    vim.api.nvim_command('bd')
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
    while i <= #lines and #lines[i] > 0 do
        i = i + 1
    end
    i = i + 1
    record.filename = lines[i]
    while i <= #lines and lines[i]:sub(1, 7) ~= 'commit ' do
        i = i + 1
    end
    return i, record
end

local function parse_time_machine(lines)
    local i = 1
    local results = {}
    while lines[i] do
        i, line_info = parse_time_machine_record(lines, i)
        table.insert(results, line_info)
    end
    return results
end

local function handle_time_machine(lines)
    vim.b.time_machine_entries = parse_time_machine(lines)
    vim.b.time_machine_cur_idx = 1
    if #vim.b.time_machine_entries >= 1 then
        git_time_machine_next()
    else
        vim.cmd[[echohl ErrorMsg | echo "No git history for file!" | echohl None]]
        git_time_machine_quit()
    end
end

function setup_timemachine_popup()
    vim.b.width = vim.fn.winwidth(0)
    vim.b.height = vim.fn.winheight(0)

    vim.b.popup_buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_option(vim.b.popup_buf, 'buftype', 'nofile')
    vim.api.nvim_buf_set_option(vim.b.popup_buf, 'modifiable', true)

    local opts = {
        focusable = false,
        style = "minimal",
        border = "rounded",
        relative = "win",
        width = 53,
        height = 4,
        anchor = "SE",
        row = vim.b.height,
        col = vim.b.width,
    }

    vim.b.popup_win = vim.api.nvim_open_win(vim.b.popup_buf, false, opts)
end

-- 'git log --no-merges -- afc/pom.xml'
local function git_time_machine()
    local relative_fname = utils.get_relative_fname()
    local line_no = vim.fn.line('.')
    vim.api.nvim_command('new')
    vim.api.nvim_command('nnoremap <buffer> <c-p> :lua require"agitator".git_time_machine_previous()<CR>')
    vim.api.nvim_command('nnoremap <buffer> <c-n> :lua require"agitator".git_time_machine_next()<CR>')
    vim.api.nvim_command('nnoremap <buffer> <c-h> :lua require"agitator".git_time_machine_copy_sha()<CR>')
    vim.api.nvim_command('nnoremap <buffer> q :lua require"agitator".git_time_machine_quit()<CR>')
    setup_timemachine_popup()
    vim.b.time_machine_rel_fname = relative_fname
    vim.b.time_machine_init_line_no = line_no
    local Job = require'plenary.job'
    local output = {}
    Job:new {
        command = 'git',
        -- i'd really want a plumbing command here, but i think there isn't one
        -- https://stackoverflow.com/a/29239964/516188
        args = {'log', '--name-only', '--no-merges', '--follow', '--date=iso', '--', relative_fname}, 
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

local function git_time_machine_copy_sha()
    local i = vim.b.time_machine_cur_idx
    local commit_sha = vim.b.time_machine_entries[i].sha
    vim.fn.setreg('+', commit_sha)
end

return {
    git_time_machine = git_time_machine,
    git_time_machine_next = git_time_machine_next,
    git_time_machine_previous = git_time_machine_previous,
    git_time_machine_copy_sha = git_time_machine_copy_sha,
    git_time_machine_quit = git_time_machine_quit,
    parse_time_machine = parse_time_machine,
}
