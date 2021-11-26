local open_file_branch = require('agitator.open_file_git_branch')
local blame = require('agitator.blame')
local time_machine = require('agitator.time_machine')

return {
    open_file_git_branch = open_file_branch.open_file_git_branch,
    git_blame = blame.git_blame,
    git_blame_close = blame.git_blame_close,
    git_blame_toggle = blame.git_blame_toggle,
    git_time_machine = time_machine.git_time_machine,
    git_time_machine_next = time_machine.git_time_machine_next,
    git_time_machine_previous = time_machine.git_time_machine_previous,
    git_time_machine_copy_sha = time_machine.git_time_machine_copy_sha,
    git_time_machine_quit = time_machine.git_time_machine_quit
}
