-- https://vi.stackexchange.com/a/3749/38754
local function open_file_branch(branch, fname)
    vim.api.nvim_exec('silent r! git show ' .. branch .. ':' .. fname, false)
    vim.api.nvim_command('1d')
    local fname_without_path = fname:match( "([^/]+)$")
    vim.api.nvim_exec('silent file [' .. branch .. '] ' .. fname_without_path, false)
    vim.api.nvim_command('filetype detect')
    vim.api.nvim_command('setlocal readonly')
    vim.bo.readonly = true
    vim.bo.modified = false
    vim.bo.modifiable = false
end

local function get_relative_fname()
    local fname = vim.fn.expand('%:p')
    return fname:gsub(vim.fn.getcwd() .. '/', '')
end

return {
    open_file_branch = open_file_branch,
    get_relative_fname = get_relative_fname
}
