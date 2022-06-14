describe("metafunction '__len'", function()
	local linq = require("lazylualinq")

	it("returns the length of the sequence", function()
		local sequence = linq { 1, 2 }

		assert.is_same(2, #sequence)
	end)
end)
