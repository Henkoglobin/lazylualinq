describe("constructor '#empty'", function()
	local linq = require("lazylualinq")

	it("returns an empty sequence", function()
		local iterator = linq.empty():getIterator()

		assert.is_same({iterator()}, { nil, nil })
	end)

	it("caches the empty sequence", function()
		local sequence1 = linq.empty()
		local sequence2 = linq.empty()

		assert.is_equals(sequence1, sequence2)
	end)
end)