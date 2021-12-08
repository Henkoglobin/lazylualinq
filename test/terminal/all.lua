describe("terminal operator '#all'", function() 
	local linq = require("lazylualinq")

	it("returns true if all items matche the predicate", function()
		local sequence = linq { 2, 4, 8, 10 }

		assert.is_true(sequence:all(function(v) return v % 2 == 0 end))
	end)

	it("passes the key to the predicate", function()
		local sequence = linq { 1, 2 }

		assert.is_true(sequence:all(function(v, k) return v == k end))
	end)

	it("returns false even one element does not match the predicate", function()
		local sequence = linq { 0, 0, 1 }

		assert.is_false(sequence:all(function(v) return v == 0 end))
	end)

	it("stops iterating when the first non-match is found", function()
		local iteratorCalled = false
		local sequence = linq.iterator(function()
			if iteratorCalled then 
				assert.fail("Iterator should not have been called again")
			end

			iteratorCalled = true

			return 1, 1
		end)

		assert.is_false(sequence:all(function(v) return v == 2 end))
	end)

	it("supports string lambdas", function() 
		local sequence = linq { 2, 4, 6, 8 }

		assert.is_true(sequence:all("v => v % 2 == 0"))
	end)
end)