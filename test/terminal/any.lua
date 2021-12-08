describe("terminal operator '#any'", function() 
	local linq = require("lazylualinq")

	describe("without a predicate", function()
		it("returns true if there is an element in the sequence", function()
			local sequence = linq { 1 }

			assert.is_true(sequence:any())
		end)

		it("returns false if there are no elements", function()
			assert.is_false(linq.empty():any())
		end)

		it("stops after the first element", function()
			local iteratorCalled = false
			local sequence = linq.iterator(function()
				if iteratorCalled then 
					assert.fail("Iterator should not have been called again")
				end

				iteratorCalled = true

				return 1, 1
			end)

			assert.is_true(sequence:any())
		end)
	end)

	describe("with a predicate", function()
		it("returns true if one item matches the predicate", function()
			local sequence = linq { 1, 2, 3, 4 }

			assert.is_true(sequence:any(function(v) return v == 2 end))
		end)

		it("passes the key to the predicate", function()
			local sequence = linq { 5, 4, 3, 2, 1 }

			assert.is_true(sequence:any(function(v, k) return v == k end))
		end)

		it("returns false if no element matches the predicate", function()
			local sequence = linq { 1, 2, 3, 4 }

			assert.is_false(sequence:any(function(v) return v == 0 end))
		end)

		it("stops iterating when the first match is found", function()
			local iteratorCalled = false
			local sequence = linq.iterator(function()
				if iteratorCalled then 
					assert.fail("Iterator should not have been called again")
				end

				iteratorCalled = true

				return 1, 1
			end)

			assert.is_true(sequence:any(function(v) return v == 1 end))
		end)

		it("supports string lambdas", function() 
			local sequence = linq { 1, 2, 3, 4 }

			assert.is_true(sequence:any("v => v == 2"))
		end)
	end)
end)