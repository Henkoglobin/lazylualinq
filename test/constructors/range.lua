describe("constructor '#range'", function()
	local linq = require("lazylualinq")

	it("requires <start>", function()
		assert.has_error(function() linq.range() end, "First argument 'start' must be a number!")
	end)

	it("requires <count>", function()
		assert.has_error(function() linq.range(0) end, "Second argument 'count' must be a positive number!")
	end)

	it("produces exactly <count> results", function()
		local iterator = linq.range(0, 3)()

		assert.same({iterator()}, {   0, 1 })
		assert.same({iterator()}, {   1, 2 })
		assert.same({iterator()}, {   2, 3 })

		-- Sequences are assumed to be over when the returned key (second value) is nil
		assert.same({iterator()}, { nil, nil })
	end)

	it("produces an empty sequence for <count> = 0", function()
		local iterator = linq.range(0, 0)()

		assert.same({iterator()}, { nil, nil })
	end)

	it("starts values at <start>", function()
		local iterator = linq.range(3, 2)()

		assert.same({iterator()}, { 3, 1})
		assert.same({iterator()}, { 4, 2})
	end)

	it("supports negative <start>", function()
		local iterator = linq.range(-1, 3)()

		assert.same({iterator()}, {  -1, 1 })
		assert.same({iterator()}, {   0, 2 })
		assert.same({iterator()}, {   1, 3 })

		assert.same({iterator()}, { nil, nil })
	end)
end)