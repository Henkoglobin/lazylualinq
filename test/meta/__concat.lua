describe("metafunction '__concat'", function()
	local linq = require("lazylualinq")

	it("concatenates two sequences", function()
		local seq1 = linq { "Hello" }
		local seq2 = linq { "World" }

		local iterator = (seq1 .. seq2):getIterator()

		assert.is_same({ "Hello", 1 }, { iterator() })
		assert.is_same({ "World", 1 }, { iterator() })
		assert.is_same({ nil, nil }, { iterator() })
	end)

	it("concatenates more than two sequences in the expected order", function()
		local iterator = (
			linq { "The Way of Kings" }
			.. linq { "Words of Radiance" }
			.. linq { "Oathbringer" }
			.. linq { "Rhythm of War" }
		):getIterator()

		assert.is_same({ "The Way of Kings", 1 }, { iterator() })
		assert.is_same({ "Words of Radiance", 1 }, { iterator() })
		assert.is_same({ "Oathbringer", 1 }, { iterator() })
		assert.is_same({ "Rhythm of War", 1 }, { iterator() })
		assert.is_same({ nil, nil }, { iterator() })
	end)
end)