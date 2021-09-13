describe("constructor 'array'", function()
	local linq = require("lazylualinq")

	it("iterates numeric indices", function()
		local iterator = linq.array({ "a", "b" }):getIterator()

		assert.is_same({iterator()}, { "a", 1 })
		assert.is_same({iterator()}, { "b", 2 })
	
		assert.is_same({iterator()}, { nil, nil })
	end)

	it("ignores non-numeric indices", function()
		local iterator = linq.array({
			"a", "b", ["hello"] = "world"
		}):getIterator()

		assert.is_same({iterator()}, { "a", 1 })
		assert.is_same({iterator()}, { "b", 2 })
	
		assert.is_same({iterator()}, { nil, nil })
	end)

	it("continues yielding nil after the sequence is exhausted", function()
		local iterator = linq.array({}):getIterator()

		assert.is_same({iterator()}, { nil, nil })
		assert.is_same({iterator()}, { nil, nil })
	end)
end)