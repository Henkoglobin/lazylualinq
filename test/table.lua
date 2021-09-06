require "test._matchers"

describe("constructor 'table'", function()
    local linq = require("linq")

    it("supports empty tables", function()
        local iterator = linq.table({}):getIterator()

        assert.is_same({iterator()}, { nil, nil })
    end)

    it("yields values from the table", function()
        local iterator = linq.table({ hello = "world" }):getIterator()
        
        assert.is_same({iterator()}, { "world", "hello" })
        assert.is_same({iterator()}, { nil, nil })
    end)

    it("yields values in any order", function()
        local iterator = linq.table({
            hello = "world",
            abc = "def",
            [true] = "True"
        }):getIterator()

        for i = 1, 3 do
            assert.is_any_of({iterator()}, {
                {"world", "hello"},
                { "def", "abc" },
                { "True", true }
            })
        end

        assert.is_same({iterator()}, { nil, nil })
    end)

    it("continues yielding nil after the sequence is exhausted", function()
        local iterator = linq.table({}):getIterator()

        assert.is_same({iterator()}, { nil, nil })
        assert.is_same({iterator()}, { nil, nil })
    end)
end)