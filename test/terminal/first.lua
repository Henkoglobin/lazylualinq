describe("terminal operator 'first'", function() 
	local linq = require("lazylualinq")

	describe("without a predicate", function()
		it("returns the first element in the sequence", function()
			local sequence = linq { 1, 2, 3 }
			assert.is_same(1, sequence:first())
		end)

		it("does not iterate the sequence beyond the first element", function()
			local iteratorCalled = false
			local sequence = linq.iterator(function() 
					if iteratorCalled then
						assert.fail("Iterator should not have been called again")
					end

					iteratorCalled = true

					return 1, 1
				end)

			assert.is_same(1, sequence:first())
		end)

		it("throws an error if the sequence is empty", function() 
			local sequence = linq.empty()

			assert.has_error(function() sequence:first() end, "Sequence was empty!")
		end)
	end)

	describe("with a predicate", function() 
		it("returns the first matching element in the sequence", function()
			local sequence = linq { 1, 2, 3, 4 }
			assert.is_same(2, sequence:first(function(v) return v % 2 == 0 end))
		end)

		it("does not iterate the sequence further than necessary", function()
			local progress = 0
			
			local sequence = linq.iterator(function() 
				progress = progress + 1
				return progress 
			end)

			assert.is_same(2, sequence:first(function(v) return v % 2 == 0 end))
			assert.is_same(2, progress)
		end)

		it("throws an error if there is no matching element", function()
			local sequence = linq { 1, 3, 5, 7 }
			assert.has_error(
				function() 
					sequence:first(function(v) return v % 2 == 0 end)
				end,
				"No items matched the predicate!"
			)
		end)
	end)
end)