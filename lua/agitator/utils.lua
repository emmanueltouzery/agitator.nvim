-- https://vi.stackexchange.com/a/3749/38754
local function open_file_branch(branch, fname)
    vim.api.nvim_exec('silent r! git show ' .. branch .. ':./' .. fname, false)
    vim.api.nvim_command('1d')
    local fname_without_path = fname:match( "([^/]+)$")
    local base_bufcmd = 'silent file [' .. branch .. '] ' .. fname_without_path
    -- if we try to open twice the same file from the same branch, we get
    -- vim failures "buffer name already in use"
    if not pcall(vim.api.nvim_exec, base_bufcmd, false) then
        local succeeded = false
        local i = 2
        while not succeeded and i < 20 do
            succeeded = pcall(vim.api.nvim_exec, base_bufcmd .. ' (' .. i .. ')', false)
            i = i + 1
        end
    end
    vim.api.nvim_command('filetype detect')
    vim.api.nvim_command('setlocal readonly')
    vim.bo.readonly = true
    vim.bo.modified = false
    vim.bo.modifiable = false
end

-- https://stackoverflow.com/a/34953646/516188
function escape_pattern(text)
    return text:gsub("([^%w])", "%%%1")
end

local function get_relative_fname()
    local fname = vim.fn.expand('%:p')
    return fname:gsub(escape_pattern(vim.fn.getcwd()) .. '/', '')
end

return {
    open_file_branch = open_file_branch,
    get_relative_fname = get_relative_fname,
    escape_pattern = escape_pattern,
}
