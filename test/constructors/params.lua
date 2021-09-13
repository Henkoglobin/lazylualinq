describe("constructor 'params'", function() 
	local linq = require("lazylualinq")

	it("yields an empty sequence without parameters", function() 
		local iterator = linq.params():getIterator()

		assert.is_same({iterator()}, { nil, nil })
	end)

	it("yields all parameters passed", function()
		local iterator = linq.params("d", "e", "f"):getIterator()

		assert.same({iterator()}, {   "d", 1 })
		assert.same({iterator()}, {   "e", 2 })
		assert.same({iterator()}, {   "f", 3 })

		-- Sequences are assumed to be over when the returned key (second value) is nil
		assert.same({iterator()}, { nil, nil })
	end)

	it("stops at the first nil parameter", function()
		local iterator = linq.params("d", nil, "f"):getIterator()

		assert.same({iterator()}, {   "d", 1 })

		-- Sequences are assumed to be over when the returned key (second value) is nil
		assert.same({iterator()}, { nil, nil })
	end)
end)