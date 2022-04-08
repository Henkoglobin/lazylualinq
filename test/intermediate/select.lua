describe("intermediate function '#select'", function()
	local linq = require("lazylualinq")

	it("transforms items using the projection", function()
		local iterator = linq { 1, 2, 3, 4 }
			:select(function(v, k) return v % 3, k end)
			:getIterator()

		assert.is_same({iterator()}, { 1, 1 })
		assert.is_same({iterator()}, { 2, 2 })
		assert.is_same({iterator()}, { 0, 3 })
		assert.is_same({iterator()}, { 1, 4 })

		assert.is_same({iterator()}, { nil, nil })
	end)

	it("passes the source key to the projection", function()
		local source = linq {
			hello = 123
		}

		local iterator = source:select(function(_, k) return #k, k end)
			:getIterator()

		assert.is_same({iterator()}, { 5, "hello" })

		assert.is_same({iterator()}, { nil, nil })
	end)

	it("accepts string lambdas", function() 
		local iterator = linq { 1, 2, 3, 4 }
			:select("v % 3, k")
			:getIterator()

		assert.is_same({iterator()}, { 1, 1 })
		assert.is_same({iterator()}, { 2, 2 })
		assert.is_same({iterator()}, { 0, 3 })
		assert.is_same({iterator()}, { 1, 4 })

		assert.is_same({iterator()}, { nil, nil })
	end)

	it("streams the source lazily", function() 
		local iteratorCalls = 0

		local iterator = linq.iterator(function() 
				iteratorCalls = iteratorCalls + 1
				return iteratorCalls, iteratorCalls
			end)
			:select(function(v, k) return v, k end)
			:getIterator()

		assert.is_same(iteratorCalls, 0)

		assert.is_same({iterator()}, { 1, 1 })
		assert.is_same(iteratorCalls, 1)

		assert.is_same({iterator()}, { 2, 2 })
		assert.is_same(iteratorCalls, 2)
	end)

	it("can also be called using 'map'", function()
		local iterator = linq { 1, 2 }
			:map(function(v, k) return v * 2, k end)
			:getIterator()

		assert.is_same({iterator()}, { 2, 1 })
		assert.is_same({iterator()}, { 4, 2 })

		assert.is_same({iterator()}, { nil, nil })
	end)
end)