local blame = require('agitator.blame')
local test_utils = require('tests.test_utils')

describe("Blame parsing", function()
    it("should parse a simple case", function()
        local actual = blame.parse_blame_lines(test_utils.as_lines([[
f115609b2f2b6975de6072777e4d34b5d28e463d 1 1 2
author Emmanuel Touzery
author-mail <etouzery@gmail.com>
author-time 1637604990
author-tz +0100
committer Emmanuel Touzery
committer-mail <etouzery@gmail.com>
committer-time 1637604990
committer-tz +0100
summary fix git blame - use util.get_relative_fname
previous cdd54af44159f553d040372c93a19968a0e5c5c0 lua/agitator/blame.lua
filename lua/agitator/blame.lua
	local utils = require('agitator.utils')
f115609b2f2b6975de6072777e4d34b5d28e463d 2 2
author Emmanuel Touzery
author-mail <etouzery@gmail.com>
author-time 1637604990
author-tz +0100
committer Emmanuel Touzery
committer-mail <etouzery@gmail.com>
committer-time 1637604990
committer-tz +0100
summary fix git blame - use util.get_relative_fname
previous cdd54af44159f553d040372c93a19968a0e5c5c0 lua/agitator/blame.lua
filename lua/agitator/blame.lua
	
da988263e8242ce6908b4cbe350622753eab61a7 3 3 13
author Emmanuel Touzery
author-mail <etouzery@gmail.com>
author-time 1638022753
author-tz +0100
committer Emmanuel Touzery
committer-mail <etouzery@gmail.com>
committer-time 1638022753
committer-tz +0100
summary make the sidebar width explicit
previous 63ba3a5c4e90af3b0e6f46e0d6f3058124e98b7d lua/agitator/blame.lua
filename lua/agitator/blame.lua
        -- generated through https://medialab.github.io/iwanthue/
        ]]))
        assert.are.same("f115609b2f2b6975de6072777e4d34b5d28e463d", actual[1].sha)
        assert.are.same("Emmanuel Touzery", actual[1].author)
        assert.are.same(2021, actual[1].date.year)
        assert.are.same(11, actual[1].date.month)
        assert.are.same(22, actual[1].date.day)
        assert.are.same(19, actual[1].date.hour)
        assert.are.same(16, actual[1].date.min)
        assert.are.same("f115609b2f2b6975de6072777e4d34b5d28e463d", actual[2].sha)
        assert.are.same("Emmanuel Touzery", actual[2].author)
        assert.are.same(2021, actual[2].date.year)
        assert.are.same(11, actual[2].date.month)
        assert.are.same(22, actual[2].date.day)
        assert.are.same(19, actual[2].date.hour)
        assert.are.same(16, actual[2].date.min)
        assert.are.same("da988263e8242ce6908b4cbe350622753eab61a7", actual[3].sha)
        assert.are.same("Emmanuel Touzery", actual[3].author)
        assert.are.same(2021, actual[3].date.year)
        assert.are.same(11, actual[3].date.month)
        assert.are.same(27, actual[3].date.day)
        assert.are.same(15, actual[3].date.hour)
        assert.are.same(19, actual[3].date.min)
        assert(actual[4] == nil)
    end)
end)
