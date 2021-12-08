describe("intermediate operator '#skip'", function() 
	local linq = require("lazylualinq")

	it("skips the specified number of values", function()
		local iterator = linq { 1, 2, 3, 4 }
			:skip(2)
			:getIterator()

		assert.is_same({ 3, 3 }, { iterator() })
		assert.is_same({ 4, 4 }, { iterator() })
		
		assert.is_same({ nil, nil }, { iterator() })
	end)

	it("doesn't skip any values for count = 0", function()
		local iterator = linq { 1, 2, 3, 4 }
			:skip(0)
			:getIterator()

		assert.is_same({ 1, 1 }, { iterator() })
		assert.is_same({ 2, 2 }, { iterator() })
		assert.is_same({ 3, 3 }, { iterator() })
		assert.is_same({ 4, 4 }, { iterator() })
		
		assert.is_same({ nil, nil }, { iterator() })
	end)

	it("does not iterate the sequence beyond its maximum number of elements", function()
		local iteratorCalls = 0
		local sequence = linq.iterator(function()
			iteratorCalls = iteratorCalls + 1

			if iteratorCalls == 0 then
				return 1, 1
			elseif iteratorCalls == 1 then
				return nil, nil
			else
				assert.fail("Iterator shouldn't have been called again")
			end
		end)

		local iterator = sequence:skip(3):getIterator()

		assert.is_same({ nil, nil }, { iterator() })
	end)
end)