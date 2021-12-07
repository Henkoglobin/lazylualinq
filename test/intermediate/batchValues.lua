describe("intermediate operator '#batchValues'", function()
	local linq = require("lazylualinq")

	it("collects the specified number of values into the result", function()
		local iterator = linq { "a", "b", "c", "d", "e", "f" }
			:batchValues(3)
			:getIterator()

		local expectedFirstBatch = { "a", "b", "c" }

		assert.is_same({ expectedFirstBatch, 1 }, { iterator() })

		local expectedSecondBatch = { "d", "e", "f" }
		
		assert.is_same({ expectedSecondBatch, 2 }, { iterator() })
	end)

	it("stops when the source is exhausted", function()
		local iterator = linq { "a", "b", "c" }
			:batchValues(3)
			:getIterator()

		-- Consume the first batch
		iterator()

		assert.is_same({ nil, nil }, { iterator() })
	end)

	it("produces an incomplete batch if values are left over", function()
		local iterator = linq { "a", "b", "c" }
			:batchValues(2)
			:getIterator()

		local expectedFirstBatch = { "a", "b" }

		assert.is_same({ expectedFirstBatch, 1 }, { iterator() })

		local expectedSecondBatch = { "c" }

		assert.is_same({ expectedSecondBatch, 2 }, { iterator() })
	
		assert.is_same({ nil, nil }, { iterator() })
	end)

	it("terminates immediately if the source is empty", function()
		local iteratorCalled = false
		local iterator = linq.iterator(function() 
				if iteratorCalled then
					assert.fail("Iterator should not have been called again")
				end

				iteratorCalled = true

				return nil, nil
			end)
			:batchValues(3)
			:getIterator()

		assert.is_same({ nil, nil }, { iterator() })
		assert.is_true(iteratorCalled)
	end)
end)