describe("constructor 'rep'", function()
    local linq = require("linq")

    it("requires <count>", function()
        assert.has_error(
            function() linq.rep(1) end,
            "Second argument 'count' must be a positive number!"
        )
    end)

    it("requires <count> to be a number", function()
        assert.has_error(
            function() linq.rep(1, "a") end,
            "Second argument 'count' must be a positive number!"
        )
    end)

    it("requires <count> to be positive", function()
        assert.has_error(
            function() linq.rep(1, -3) end,
            "Second argument 'count' must be a positive number!"
        )
    end)

    it("repeats a value <count> times", function() 
        local iterator = linq.rep("a", 3):getIterator()

        assert.is_same({iterator()}, { "a", 1 })
        assert.is_same({iterator()}, { "a", 2 })
        assert.is_same({iterator()}, { "a", 3 })
        assert.is_same({iterator()}, { nil, nil })
    end)

    it("supports <count> = 0", function() 
        local iterator = linq.rep("a", 0):getIterator()
        
        assert.is_same({iterator()}, { nil, nil })
    end)

    it("supports <value> = nil", function()
        local iterator = linq.rep(nil, 3):getIterator()

        assert.is_same({iterator()}, { nil, 1 })
        assert.is_same({iterator()}, { nil, 2 })
        assert.is_same({iterator()}, { nil, 3 })
        assert.is_same({iterator()}, { nil, nil })
    end)
end)