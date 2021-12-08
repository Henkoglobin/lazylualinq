describe("intermediate operator '#selectMany'", function()
	local linq = require("lazylualinq")

	it("flattens a sequence of sequences", function()
		local iterator = linq {
				linq { 1, 2, 3, 4 },
				linq { 5, 6, 7, 8 }
			}
			:selectMany(function(inner) return inner end)
			:getIterator()
		
		assert.is_same({iterator()}, { 1, 1 })
		assert.is_same({iterator()}, { 2, 2 })
		assert.is_same({iterator()}, { 3, 3 })
		assert.is_same({iterator()}, { 4, 4 })

		assert.is_same({iterator()}, { 5, 1 })
		assert.is_same({iterator()}, { 6, 2 })
		assert.is_same({iterator()}, { 7, 3 })
		assert.is_same({iterator()}, { 8, 4 })

		assert.is_same({iterator()}, { nil, nil })
	end)

	it("handles an empty outer sequence well", function() 
		local iterator = linq.empty()
			:selectMany(function(inner) return inner end)
			:getIterator()
		
		assert.is_same({iterator()}, { nil, nil })
	end)

	it("handles an empty inner sequence well", function() 
		local iterator = linq { linq.empty(), linq { 1 } }
			:selectMany(function(inner) return inner end)
			:getIterator()

		assert.is_same({iterator()}, { 1, 1 })

		assert.is_same({iterator()}, { nil, nil })
	end)

	it("supports a string lambda as projection", function()
		local iterator = linq { linq { 1, 2 }, linq { 3, 4 } }
			:selectMany("inner => inner")
			:getIterator()
		
		assert.is_same({iterator()}, { 1, 1 })
		assert.is_same({iterator()}, { 2, 2 })

		assert.is_same({iterator()}, { 3, 1 })
		assert.is_same({iterator()}, { 4, 2 })
		
		assert.is_same({iterator()}, { nil, nil })
	end)

	it("iterates tables returned by the projection", function()
		local iterator = linq {
				{ "abc", "def" },
				{ "ghi" }
			}
			:selectMany(function(inner) return inner end)
			:getIterator()

		assert.is_same({iterator()}, { "abc", 1 })
		assert.is_same({iterator()}, { "def", 2 })
		assert.is_same({iterator()}, { "ghi", 1 })

		assert.is_same({iterator()}, { nil, nil })
	end)

	it("uses the 'new' constructor semantics to iterate inner sequences", function()
		-- Each of the inner tables is passed to linq.new(...), which means
		-- that the keys will be preserved
		local iterator = linq {
				{ hello = "world" },
				{ hello = "世界" }
			}
			:selectMany(function(inner) return inner end)
			:getIterator()

		assert.is_same({iterator()}, { "world", "hello" })
		assert.is_same({iterator()}, { "世界", "hello" })

		assert.is_same({iterator()}, { nil, nil })
	end)

	describe("with a result projection", function() 
		it("uses outer and inner element values and keys", function()
			local iterator = linq { "hello", "world" }
				:selectMany(
					function(word) return word:gmatch(".") end,
					function(outerV, outerK, innerV, innerK)
						return outerV .. ": " .. innerV, 10 * outerK + innerK
					end
				)
				:getIterator()
			
			assert.is_same({iterator()}, { "hello: h", 11 })
			assert.is_same({iterator()}, { "hello: e", 12 })
			assert.is_same({iterator()}, { "hello: l", 13 })
			assert.is_same({iterator()}, { "hello: l", 14 })
			assert.is_same({iterator()}, { "hello: o", 15 })

			assert.is_same({iterator()}, { "world: w", 21 })
			assert.is_same({iterator()}, { "world: o", 22 })
			assert.is_same({iterator()}, { "world: r", 23 })
			assert.is_same({iterator()}, { "world: l", 24 })
			assert.is_same({iterator()}, { "world: d", 25 })
		
			assert.is_same({iterator()}, { nil, nil })
		end)

		it("uses numeric keys if no key is returned", function() 
			local iterator = linq { "hello", "world" }
				:selectMany(
					function(word) return word:gmatch(".") end,
					function(outer, _, inner, _) return outer .. ": " .. inner end
				)
				:getIterator()
			
			assert.is_same({iterator()}, { "hello: h", 1 })
			assert.is_same({iterator()}, { "hello: e", 2 })
			assert.is_same({iterator()}, { "hello: l", 3 })
			assert.is_same({iterator()}, { "hello: l", 4 })
			assert.is_same({iterator()}, { "hello: o", 5 })
			assert.is_same({iterator()}, { "world: w", 6 })
			assert.is_same({iterator()}, { "world: o", 7 })
			assert.is_same({iterator()}, { "world: r", 8 })
			assert.is_same({iterator()}, { "world: l", 9 })
			assert.is_same({iterator()}, { "world: d", 10 })
		
			assert.is_same({iterator()}, { nil, nil })
		end)

		it("supports string lambdas", function()
			local iterator = linq { "hello", "world" }
				:selectMany("v => v:gmatch('.')", "v, _, v2 => v .. ': ' .. v2") 
				:getIterator()

				assert.is_same({iterator()}, { "hello: h", 1 })
				assert.is_same({iterator()}, { "hello: e", 2 })
				assert.is_same({iterator()}, { "hello: l", 3 })
				assert.is_same({iterator()}, { "hello: l", 4 })
				assert.is_same({iterator()}, { "hello: o", 5 })
				assert.is_same({iterator()}, { "world: w", 6 })
				assert.is_same({iterator()}, { "world: o", 7 })
				assert.is_same({iterator()}, { "world: r", 8 })
				assert.is_same({iterator()}, { "world: l", 9 })
				assert.is_same({iterator()}, { "world: d", 10 })

				assert.is_same({iterator()}, { nil, nil })
		end)
	end)
end)