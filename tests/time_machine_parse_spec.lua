local time_machine = require('agitator.time_machine')
local test_utils = require('tests.test_utils')

describe("Git log parsing", function()
    it("should parse a simple case", function()
        local actual = time_machine.parse_time_machine(test_utils.as_lines([[
commit 63ba3a5c4e90af3b0e6f46e0d6f3058124e98b7d
Author: Emmanuel Touzery <etouzery@gmail.com>
Date:   2021-11-26 21:55:30 +0100

    blame: simplify close, implement toggle

commit a5a3aaf58ea9ae6e1852d47a5fcada3b839aea00
Author: Emmanuel Touzery <etouzery@gmail.com>
Date:   2021-11-21 19:29:11 +0100

    oops

commit 74fd37f12409e36952e8a2f8d0cfdc991b9c873f
Author: Emmanuel Touzery <etouzery@gmail.com>
Date:   2021-11-21 19:27:27 +0100

    add time_machine, make blame functions local
        ]]))
        assert.are.same("63ba3a5c4e90af3b0e6f46e0d6f3058124e98b7d", actual[1].sha)
        assert.are.same("Emmanuel Touzery", actual[1].author)
        assert.are.same("2021-11-26 21:55", actual[1].date)
        assert.are.same("blame: simplify close, implement toggle", actual[1].message)
        assert.are.same("a5a3aaf58ea9ae6e1852d47a5fcada3b839aea00", actual[2].sha)
        assert.are.same("Emmanuel Touzery", actual[2].author)
        assert.are.same("2021-11-21 19:29", actual[2].date)
        assert.are.same("oops", actual[2].message)
        assert.are.same("74fd37f12409e36952e8a2f8d0cfdc991b9c873f", actual[3].sha)
        assert.are.same("Emmanuel Touzery", actual[3].author)
        assert.are.same("2021-11-21 19:27", actual[3].date)
        assert.are.same("add time_machine, make blame functions local", actual[3].message)
        assert(actual[4] == nil)
    end)
end)
