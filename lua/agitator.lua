local open_file_branch = require('agitator.open_file_git_branch')
local blame = require('agitator.blame')
local time_machine = require('agitator.time_machine')
local search_in_added = require('agitator.search_in_added')

return {
    open_file_git_branch = open_file_branch.open_file_git_branch,
    search_git_branch = open_file_branch.search_git_branch,
    git_blame = blame.git_blame,
    git_blame_close = blame.git_blame_close,
    git_blame_toggle = blame.git_blame_toggle,
    git_blame_commit_for_line = blame.git_blame_commit_for_line,
    git_time_machine = time_machine.git_time_machine,
    git_time_machine_next = time_machine.git_time_machine_next,
    git_time_machine_previous = time_machine.git_time_machine_previous,
    git_time_machine_copy_sha = time_machine.git_time_machine_copy_sha,
    git_time_machine_quit = time_machine.git_time_machine_quit,
    search_in_added = search_in_added.search_in_added,
}
