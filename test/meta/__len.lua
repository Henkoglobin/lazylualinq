describe("metafunction '__len'", function()
	local linq = require("lazylualinq")

	local major, minor = _VERSION:match("Lua (%d).(%d)")
	local major, minor = tonumber(major), tonumber(minor)
	local lenMetamethodAvailable = major > 5 or (major == 5 and minor >= 2)

	it("returns the length of the sequence", function()
		if not lenMetamethodAvailable then
			pending("__pairs is not available in Lua 5.1 and earlier.")
			return
		end

		local sequence = linq { 1, 2 }

		assert.is_same(2, #sequence)
	end)
end)
