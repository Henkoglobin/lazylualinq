describe("intermediate function '#windowed'", function()
    local linq = require("lazylualinq")

    it("implements a sliding window", function()
        local iterator = linq { 1, 2, 3, 4, 5 }
            :windowed(3)
            :getIterator()

        assert.is_same({ { 1, 2, 3 }, 1 }, { iterator() })
        assert.is_same({ { 2, 3, 4 }, 2 }, { iterator() })
        assert.is_same({ { 3, 4, 5 }, 3 }, { iterator() })
        assert.is_same({ nil, nil }, { iterator() })
    end)

    it("returns a new table for each item", function()
        local iterator = linq { 1, 2, 3, 4 }
            :windowed(3)
            :getIterator()

        local a = iterator()
        local b = iterator()

        assert.is_not_equal(a, b)
        assert.is_same({ 1, 2, 3 }, a)
        assert.is_same({ 2, 3, 4 }, b)
    end)

    it("produces an empty sequence if the source is too short for a single window", function()
        local iterator = linq { 1, 2 }
            :windowed(3)
            :getIterator()

        assert.is_same({ nil, nil }, { iterator() })
    end)
end)