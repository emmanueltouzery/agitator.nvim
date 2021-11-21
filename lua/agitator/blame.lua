function parse_blame_record(lines, i)
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
        end
        i = i + 1
    end
    i = i + 1
    return i, record
end

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

function render_blame_sidebar(results)
    local fname = vim.fn.expand('%:p')
    vim.api.nvim_command('leftabove 30 vnew')
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
            prev_row = string.format('%02d-%02d-%02d %s',
                r.date.year, r.date.month, r.date.day, r.author)

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
    local fname_without_path = fname:match( "([^/]+)$")
    vim.api.nvim_exec('silent file [blame] ' .. fname_without_path, false)
    vim.bo.readonly = true
    vim.bo.modified = false
    vim.bo.modifiable = false
end

-- https://www.reddit.com/r/vim/comments/9ydreq/vanilla_solutions_to_git_blame/ea1sgej/
function position_blame_sidebar()
    vim.api.nvim_command('set scrollbind')
    vim.api.nvim_command('wincmd p')
    vim.api.nvim_command('set scrollbind')
end

function handle_blame(lines)
    local i = 1
    local results = {}
    while lines[i] do
        i, line_info = parse_blame_record(lines, i)
        table.insert(results, line_info)
    end
    render_blame_sidebar(results)
    position_blame_sidebar()
end

function git_blame()
    local relative_fname = get_relative_fname()
    local Job = require'plenary.job'
    local output = {}
    Job:new {
        command = 'git',
        -- i think -p only would be maybe faster, git's output differs with
        -- -p or --line-porcelain! I mean I see different authors for different
        -- lines between these flags. And everyone matches with --line-porcelain.
        -- Also, -w, ignore whitespace, is nice, and intellij does it, but
        -- gitsigns doesn't, and i'd like to match with gitsigns.
        -- args = {'blame', relative_fname, '--line-porcelain', '-w'},
        args = {'blame', relative_fname, '--line-porcelain'},
        on_stdout = function(error, data, self)
            table.insert(output, data)
        end,
        on_exit = function(self, code, signal)
            vim.schedule_wrap(function()
                handle_blame(output)
            end)()
        end
    }:start()
end

function git_blame_close()
    local fname = vim.fn.expand('%:p')
    local fname_without_path = fname:match("([^/]+)$")
    local last_buf_id = vim.fn.bufnr('$')
    local i = 1
    while i <= last_buf_id do
        if vim.fn.bufexists(i) and vim.fn.bufname(i):find('^%[blame%] ' .. fname_without_path) ~= nil then
            vim.api.nvim_command("bd " .. i)
            i = last_buf_id + 1
        end
        i = i + 1
    end
end

return {
    git_blame = git_blame,
    git_blame_close = git_blame_close
}
