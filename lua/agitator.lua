local open_file_branch = require('agitator.open_file_git_branch')
local blame = require('agitator.blame')

return {
    open_file_git_branch = open_file_branch.open_file_git_branch,
    git_blame = blame.git_blame,
    git_blame_close = blame.git_blame_close
}
