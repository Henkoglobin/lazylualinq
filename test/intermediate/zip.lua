describe("intermediate operator #zip", function()
    local linq = require("lazylualinq")

    it("only iterates until one sequence runs out of items", function()
        local iterator = linq { "foo", "egg", "hello" }
            :zip(linq{ "bar", "spam" }, function(l, _, r) return l .. r end)
            :getIterator()

        assert.is_same({"foobar", 1}, { iterator() })
        assert.is_same({"eggspam", 2}, { iterator() })
    end)
end)