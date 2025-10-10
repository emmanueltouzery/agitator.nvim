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
        force_length(record.author, vim.b.popup_width),
        force_length(record.message, vim.b.popup_width),
        record.date .. " - " .. (entries_count - i + 1) .. "/" .. entries_count,
        vim.b.popup_last_line
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
    local relative_fname = complete_fname:gsub(utils.escape_pattern(utils.get_cwd()) .. '/', '')
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

local function git_time_machine_focus(sha)
    for index, entry in ipairs(vim.b.time_machine_entries) do
        -- The param sha could be a short sha, so check against the start of the time machine full sha
        if string.sub(entry.sha, 1, #sha) == sha then
            vim.b.time_machine_cur_idx = index
            git_time_machine_display()
            return true
        end
    end
    vim.cmd([[echohl ErrorMsg | echo "Given commit sha doesn't exist in this file's history" | echohl None]])
    return false
end

local function git_time_machine_previous()
    if vim.b.time_machine_cur_idx < #vim.b.time_machine_entries then
        vim.b.time_machine_cur_idx = vim.b.time_machine_cur_idx + 1
    end
    git_time_machine_display()
end

local function git_time_machine_quit(opts)
    if vim.api.nvim_win_is_valid(vim.b.popup_win) then
        vim.api.nvim_win_close(vim.b.popup_win, true)
    end
    if vim.api.nvim_buf_is_valid(vim.b.popup_buf) then
        vim.api.nvim_buf_delete(vim.b.popup_buf, {force=true})
    end
    local bufnr = vim.fn.bufnr('%')
    local orig_bufnr = vim.b.orig_bufnr
    local use_current_win = false
    if opts and opts.use_current_win then
        use_current_win = opts.use_current_win
    end
    vim.b.buf__closing = true
    -- need the schedule_wrap and pcall in case this is
    -- called from an autocmd, in which case the buffer is "busy"
    -- since an autocmd is running on it
    vim.defer_fn(function()
        if use_current_win then
            if vim.api.nvim_buf_is_valid(orig_bufnr) then
                vim.api.nvim_win_set_buf(0, orig_bufnr)
            end
        end
        vim.defer_fn(function()
            pcall(vim.api.nvim_buf_delete, bufnr, {force=true})
        end, 50)
    end, 50)
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

local function handle_time_machine(lines, opts)
    vim.b.time_machine_entries = parse_time_machine(lines)
    vim.b.time_machine_cur_idx = 1
    if #vim.b.time_machine_entries >= 1 then
        -- Focus the given commit sha if possible
        if opts ~= nil and opts.commit_sha then
            if git_time_machine_focus(opts.commit_sha) then
                return
            end
        end
        -- Fallback to next
        git_time_machine_next()
    else
        vim.cmd([[echohl ErrorMsg | echo "No git history for file!" | echohl None]])
        git_time_machine_quit(opts)
    end
end

function setup_timemachine_popup(opts)
    vim.b.width = vim.fn.winwidth(0)
    vim.b.height = vim.fn.winheight(0)

    vim.b.popup_buf = vim.api.nvim_create_buf(false, true)
    vim.b.popup_last_line = (opts and opts.popup_last_line) or '<c-p> Previous | <c-n> Next | <c-h> Copy SHA | [q]uit'
    vim.b.popup_width = (opts and opts.popup_width) or 53
    vim.api.nvim_buf_set_option(vim.b.popup_buf, 'buftype', 'nofile')
    vim.api.nvim_buf_set_option(vim.b.popup_buf, 'modifiable', true)
    vim.api.nvim_buf_set_option(vim.b.popup_buf, 'filetype', 'AgitatorTimeMachine')

    local opts = {
        focusable = false,
        style = "minimal",
        border = "rounded",
        relative = "win",
        width = vim.b.popup_width,
        height = 4,
        anchor = "SE",
        row = vim.b.height,
        col = vim.b.width,
    }

    vim.b.popup_win = vim.api.nvim_open_win(vim.b.popup_buf, false, opts)
end

local function git_time_machine(opts)
    local relative_fname = utils.get_relative_fname()
    local line_no = vim.fn.line('.')
    if opts ~= nil and opts.use_current_win then
        local cur_buf = vim.api.nvim_win_get_buf(0)
        vim.api.nvim_command('enew')
        vim.b.orig_bufnr = cur_buf
    else
        vim.api.nvim_command('new')
    end
    local bufnr = vim.fn.bufnr('%')
    vim.api.nvim_create_autocmd({"BufUnload", "BufHidden"}, {
        buffer = bufnr,
        callback = function(ev)
            vim.api.nvim_buf_call(bufnr, function()
                if not vim.b.buf__closing then
                    git_time_machine_quit(opts)
                end
            end)
        end
    })
    setup_timemachine_popup(opts)
    if opts ~= nil and opts.set_custom_shortcuts ~= nil then
        opts.set_custom_shortcuts(bufnr)
    else
        vim.keymap.set('n', '<c-p>', function()
            require"agitator".git_time_machine_previous()
        end, {buffer = 0})
        vim.keymap.set('n', '<c-n>', function()
            require"agitator".git_time_machine_next()
        end, {buffer = 0})
        vim.keymap.set('n', '<c-h>', function()
            require"agitator".git_time_machine_copy_sha()
        end, {buffer = 0})
        vim.keymap.set('n', 'q', function()
            require"agitator".git_time_machine_quit(opts)
        end, {buffer = 0})
    end
    vim.b.time_machine_rel_fname = relative_fname
    vim.b.time_machine_init_line_no = line_no
    local Job = require'plenary.job'
    local output = {}
    Job:new {
        command = 'git',
        -- i'd really want a plumbing command here, but i think there isn't one
        -- https://stackoverflow.com/a/29239964/516188
        -- enforce the pretty configuration in case the user customizes it: https://github.com/emmanueltouzery/agitator.nvim/issues/13
        args = {'log', '--name-only', '--no-merges', '--follow', '--date=iso', '--pretty=medium', '--', relative_fname}, 
        on_stdout = function(error, data, self)
            table.insert(output, data)
        end,
        on_exit = function(self, code, signal)
            vim.schedule_wrap(function()
                handle_time_machine(output, opts)
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
