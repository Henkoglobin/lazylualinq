describe("intermediate function '#where'", function()
	local linq = require("lazylualinq")

	it("filters items that don't match the predicate", function()
		local iterator = linq { 1, 2, 3, 4 }
			:where(function(v) return v % 2 == 0 end)
			:getIterator()

		assert.is_same({iterator()}, { 2, 2 })
		assert.is_same({iterator()}, { 4, 4 })

		assert.is_same({iterator()}, { nil, nil })
	end)

	it("passes the source key to the predicate", function()
		local source = linq {
			hello = 123,
			abc = 456
		}

		local iterator = source:where(function(_, k) return #k == 3 end)
			:getIterator()

		assert.is_same({iterator()}, { 456, "abc" })

		assert.is_same({iterator()}, { nil, nil })
	end)

	it("accepts string lambdas", function() 
		local iterator = linq { 1, 2, 3, 4 }
			:where("v % 2 == 0")
			:getIterator()

		assert.is_same({iterator()}, { 2, 2 })
		assert.is_same({iterator()}, { 4, 4 })

		assert.is_same({iterator()}, { nil, nil })
	end)

	it("streams the source lazily", function() 
		local iteratorCalls = 0

		local iterator = linq.iterator(function() 
				iteratorCalls = iteratorCalls + 1
				return iteratorCalls, iteratorCalls
			end)
			:where(function() return true end)
			:getIterator()

		assert.is_same(iteratorCalls, 0)

		assert.is_same({iterator()}, { 1, 1 })
		assert.is_same(iteratorCalls, 1)

		assert.is_same({iterator()}, { 2, 2 })
		assert.is_same(iteratorCalls, 2)
	end)

	it("can also be called using 'filter'", function()
		local iterator = linq { 1, 2, 3, 4 }
			:filter(function(v) return v % 2 == 0 end)
			:getIterator()

		assert.is_same({iterator()}, { 2, 2 })
		assert.is_same({iterator()}, { 4, 4 })

		assert.is_same({iterator()}, { nil, nil })
	end)
end)