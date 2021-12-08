describe("intermediate operator '#take'", function()
	local linq = require("lazylualinq")

	it("yields the specified number of values if there are enough", function()
		local iterator = linq { "a", "b", "c" }
			:take(2)
			:getIterator()

		assert.is_same({ "a", 1 }, { iterator() })
		assert.is_same({ "b", 2 }, { iterator() })

		assert.is_same({ nil, nil }, { iterator() })
	end)

	it("yields an empty sequence for count = 0", function()
		local iterator = linq { "a", "b", "c" }
			:take(0)
			:getIterator()

		assert.is_same({ nil, nil }, { iterator() })
	end)

	it("yields all available elements for count > #source", function()
		local iterator = linq { "a", "b" }
			:take(100)
			:getIterator()

		assert.is_same({ "a", 1 }, { iterator() })
		assert.is_same({ "b", 2 }, { iterator() })

		assert.is_same({ nil, nil }, { iterator() })
	end)

	it("stops iterating the source after it's been exhausted", function() 
		local iteratorCalls = 0
		local source = linq.iterator(function()
			iteratorCalls = iteratorCalls + 1

			if iteratorCalls == 2 then
				return nil, nil
			elseif iteratorCalls > 2 then
				assert.fail("Iterator should not have been called again")
			end

			return 1, 1
		end)

		local iterator = source
			:take(20)
			:getIterator()

		for i = 1, 20 do
			iterator()
		end
	end)
end)