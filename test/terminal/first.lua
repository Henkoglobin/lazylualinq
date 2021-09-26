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
	end)
end)