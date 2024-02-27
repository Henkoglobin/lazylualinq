
describe("for loop usage", function()
	local linq = require("lazylualinq")

	it("throws error when getIterator is not called", function()
		local seq = linq { 1, 2, 3 }

        assert.has_error(function() 
            for _x in seq do
            end
        end)

        local items = {}
        for x in seq() do
            table.insert(items, x)
        end

		assert.is_same(#items, 3)
		assert.is_same(items[1], 1)
		assert.is_same(items[2], 2)
		assert.is_same(items[3], 3)

        items = {}
        for x in seq:getIterator() do
            table.insert(items, x)
        end

		assert.is_same(#items, 3)
		assert.is_same(items[1], 1)
		assert.is_same(items[2], 2)
		assert.is_same(items[3], 3)
	end)
end)
