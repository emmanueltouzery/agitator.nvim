local utils = require('agitator.utils')

-- generated through https://medialab.github.io/iwanthue/
-- H 0-360
-- C 30-80
-- L 5-100
COLORS = {
    "#7971fd", "#f759d4", "#ffdb72", "#62438d", "#5b6700", "#7cb3ff", "#01d890", "#fdbbff",
    "#bfffa3", "#01a4a2", "#005baf", "#afffd8", "#db0051", "#f6ab06", "#276e00", "#ffcd9f",
    "#01b039", "#902871", "#017eef", "#ff6943", "#fa2f98", "#3643bf", "#d60996", "#66501f",
    "#f0ff5f", "#ff86d2", "#9d2326", "#ba9600", "#01cce4", "#008554", "#00feed", "#9eab00",
    "#d2dc2d",
}
DEFAULT_SIDEBAR_WIDTH = 30

local function parse_blame_record(lines, i)
    local record = {}
    record.sha = lines[i]:sub(1, 40)
    i = i + 1
    while lines[i] and not lines[i]:match('^\t') do
        local l = lines[i]
        if l:match('^author ') then
            record.author = l:sub(8)
        -- for some reason author-time doesn't match, so i put a dot
        elseif l:match('^author.time ') then
            record.date = os.date('*t', l:sub(13))
        elseif l:match('^summary ') then
            record.summary = l:sub(9)
        end
        i = i + 1
    end
    i = i + 1
    return i, record
end

local function render_blame_sidebar(results, opts)
    local fname = vim.fn.expand('%:p')
    local save_pos = vim.fn.getpos(".")
    save_pos[3] = 1 -- reset the column to the leftmost one
    local w = DEFAULT_SIDEBAR_WIDTH
    if opts ~= nil and opts.sidebar_width ~= nil then
        w = opts.sidebar_width
    end
    vim.api.nvim_command('leftabove ' .. w .. ' vnew')
    local i = 1
    while COLORS[i] do
        vim.api.nvim_command("highlight BLAME_COL" .. i .. " guifg=" .. COLORS[i])
        i = i + 1
    end
    i = 1
    local prev_row
    local prev_color
    local sha_to_highlight = {}
    local last_color = 1
    while results[i] do
        local r = results[i]
        if r['author'] ~= nil then
            if opts ~= nil and opts.formatter ~= nil then
                prev_row = opts.formatter(r)
            else
                prev_row = string.format('%02d-%02d-%02d %s',
                    r.date.year, r.date.month, r.date.day, r.author)
            end

            if sha_to_highlight[r.sha] == nil then
                sha_to_highlight[r.sha] = "BLAME_COL" .. (last_color % #COLORS)
                last_color = last_color + 1
            end
            prev_color = sha_to_highlight[r.sha]
        end
        vim.fn.append('$', prev_row)
        vim.api.nvim_buf_add_highlight(0, -1, prev_color, i, 0, -1)
        i = i + 1
    end
    vim.api.nvim_command('0delete')
    vim.api.nvim_command('setlocal readonly')
    vim.api.nvim_command('set nowrap')
    vim.api.nvim_command('set nonumber')
    vim.api.nvim_command('set norelativenumber')
    vim.api.nvim_command('set filetype=agitator')
    local fname_without_path = fname:match( "([^/]+)$")
    vim.api.nvim_exec('silent file [blame] ' .. fname_without_path, false)
    vim.bo.readonly = true
    vim.bo.modified = false
    vim.bo.modifiable = false
    return save_pos
end

local function git_blame_close()
    vim.api.nvim_command('set noscrollbind')
    vim.api.nvim_command('set nocursorbind')
    local fname = vim.fn.expand('%:p')
    vim.api.nvim_command("bd " .. vim.b.blame_buf_id)
    vim.b.blame_buf_id = nil
end

-- https://www.reddit.com/r/vim/comments/9ydreq/vanilla_solutions_to_git_blame/ea1sgej/
local function position_blame_sidebar(save_pos)
    local blame_buf_id = vim.fn.bufnr('%')
    vim.fn.setpos('.', save_pos)
    vim.api.nvim_command('setlocal scrollbind')
    vim.api.nvim_command('setlocal cursorbind nowrap')
    vim.api.nvim_command('wincmd p') -- return to the original window

    -- if to avoid adding tons of autocmds if the user toggles
    -- blame multiple times on a single buffer
    if vim.b.blame_buf_id == nil then
        vim.api.nvim_create_autocmd(
        { "BufHidden", "BufUnload" },
        {
            callback = function()
                if vim.b.blame_buf_id ~= nil then
                    git_blame_close()
                end
            end,
            buffer = vim.fn.bufnr('%'),
            desc = "Turn off relative line numbering when the buffer is exited.",
        })
    end

    vim.b.blame_buf_id = blame_buf_id
    vim.api.nvim_command('setlocal scrollbind')
    vim.api.nvim_command('setlocal cursorbind')
    vim.api.nvim_command('syncbind')
end

local function parse_blame_lines(lines)
    local i = 1
    local results = {}
    while lines[i] do
        i, line_info = parse_blame_record(lines, i)
        table.insert(results, line_info)
    end
    return results
end

local function handle_blame(lines, opts)
    local results = parse_blame_lines(lines)
    local save_pos = render_blame_sidebar(results, opts)
    position_blame_sidebar(save_pos)
end

local function git_blame(opts)
    local Job = require'plenary.job'
    local output = {}
    local relative_fname
    local buf_fname, buf_commit = utils.fname_commit_associated_with_buffer()
    if buf_fname ~= nil then
        relative_fname = buf_fname
    else 
        relative_fname = utils.get_relative_fname()
    end
    -- i think -p only would be maybe faster, git's output differs with
    -- -p or --line-porcelain! I mean I see different authors for different
    -- lines between these flags. And everyone matches with --line-porcelain.
    -- Also, -w, ignore whitespace, is nice, and intellij does it, but
    -- gitsigns doesn't, and i'd like to match with gitsigns.
    -- args = {'blame', relative_fname, '--line-porcelain', '-w'},
    local git_args = {'blame', relative_fname, '--line-porcelain'}
    local job_params = {
        command = 'git',
        args = git_args,
        on_stdout = function(error, data, self)
            table.insert(output, data)
        end,
        on_exit = function(self, code, signal)
            vim.schedule_wrap(function()
                handle_blame(output, opts)
            end)()
        end
    }
    if buf_commit ~= nil then
        table.insert(git_args, vim.b.agitator_commit)
        job_params.cwd = utils.git_root_folder()
    end
    Job:new(job_params):start()
end

local function git_blame_toggle(opts)
    if vim.b.blame_buf_id ~= nil then
        git_blame_close()
    else
        git_blame(opts)
    end
end

local function git_blame_commit_for_line()
    local relative_fname, commit = utils.fname_commit_associated_with_buffer()
    if relative_fname == nil then
        relative_fname = utils.get_relative_fname()
    end
    local output
    local git_args = {'blame', '-L' .. vim.fn.line('.') .. ',' .. vim.fn.line('.'), relative_fname}
    local job_params = {
        command = 'git',
        args = git_args,
        on_stdout = function(error, data, self)
            output = data:gsub("%s.*$", "")
        end,
    }
    if commit ~= nil then
        table.insert(git_args, commit)
        job_params.cwd = utils.git_root_folder()
    end
    local Job = require'plenary.job'
    Job:new(job_params):sync()
    return output
end

return {
    git_blame = git_blame,
    git_blame_close = git_blame_close,
    git_blame_toggle = git_blame_toggle,
    parse_blame_lines = parse_blame_lines,
    git_blame_commit_for_line = git_blame_commit_for_line,
}
