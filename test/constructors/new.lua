require "test._matchers"

describe("constructor 'new'", function() 
	local linq = require("lazylualinq")

	describe("without parameters", function()
		it("returns an empty sequence", function()
			local iterator = linq.new():getIterator()

			assert.is_same({iterator()}, { nil, nil })
		end)
	end)

	describe("with one parameter", function()
		describe("that is a stream", function()
			it("just returns the sequence", function()
				local sequence = linq.params("a", "b")
				local iterator = linq.new(sequence):getIterator()

				assert.is_same({iterator()}, { "a", 1 })
				assert.is_same({iterator()}, { "b", 2 })
				assert.is_same({iterator()}, { nil, nil })
			end)
		end)

		describe("that is a table with a value at [1]", function() 
			it("yields values with numeric keys", function()
				local iterator = linq.new({ "a", "b" }):getIterator()

				assert.is_same({iterator()}, { "a", 1 })
				assert.is_same({iterator()}, { "b", 2 })
				assert.is_same({iterator()}, { nil, nil })
			end)

			it("ignores non-numeric indices", function()
				local iterator = linq.new({
					"a", "b", ["hello"] = "world"
				}):getIterator()

				assert.is_same({iterator()}, { "a", 1 })
				assert.is_same({iterator()}, { "b", 2 })
				assert.is_same({iterator()}, { nil, nil })
			end)
		end)

		describe("that is a table without a value at [1]", function()
			it("yields all values from the table, in any order", function()
				local iterator = linq.new({ abc = "def", hello = "world" }):getIterator()

				for _ = 1, 2 do
					assert.is_any_of({iterator()}, {
						{   "def", "abc" },
						{ "world", "hello" }
					})
				end

				assert.is_same({iterator()}, { nil, nil })
			end)
		end)

		describe("that is a function", function()
			it("calls it repeatedly and yields the results", function()
				local input = "hello world"
				local iterator = linq.new(input:gmatch("%w+")):getIterator()

				assert.is_same({iterator()}, { "hello", 1 })
				assert.is_same({iterator()}, { "world", 2 })
				assert.is_same({iterator()}, { nil, nil })
			end)
		end)
	end)

	describe("with any other number of parameters", function() 
		it("yields the parameters as a sequence", function()
			local iterator = linq.new("a", "b"):getIterator()

			assert.is_same({iterator()}, { "a", 1 })
			assert.is_same({iterator()}, { "b", 2 })
			assert.is_same({iterator()}, { nil, nil })
		end)
	end)
end)