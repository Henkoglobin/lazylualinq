describe("constructor '#iterator'", function()
	local linq = require("lazylualinq")

	it("calls the passed function repeatedly to retrieve items", function()
		local progress = 0

		local iterator = linq.iterator(function()
				progress = progress + 1
				return progress % 3, progress
			end)
			:getIterator()

		assert.is_same({ iterator() }, { 1, 1 })
		assert.is_same({ iterator() }, { 2, 2 })
		assert.is_same({ iterator() }, { 0, 3 })
		assert.is_same({ iterator() }, { 1, 4 })
	end)

	it("yields a numeric key if the function does not provide one", function()
		local progress = 0
		local iterator = linq.iterator(function()
				progress = progress + 1
				return progress % 3
			end)
			:getIterator()

			assert.is_same({ iterator() }, { 1, 1 })
			assert.is_same({ iterator() }, { 2, 2 })
			assert.is_same({ iterator() }, { 0, 3 })
			assert.is_same({ iterator() }, { 1, 4 })
	end)

	it("caches results when multiple iterators are created", function()
		local progress = 0
		local sequence = linq.iterator(function()
			progress = progress + 1
			return progress % 3, progress
		end)

		local iterator1 = sequence:getIterator()
		local iterator2 = sequence:getIterator()

		assert.is_same({ iterator1() }, { 1, 1 })
		assert.is_same({ iterator1() }, { 2, 2 })
		assert.is_same({ iterator1() }, { 0, 3 })
		assert.is_same({ iterator1() }, { 1, 4 })

		assert.is_same(progress, 4)

		assert.is_same({ iterator2() }, { 1, 1 })
		assert.is_same({ iterator2() }, { 2, 2 })
		assert.is_same({ iterator2() }, { 0, 3 })
		assert.is_same({ iterator2() }, { 1, 4 })

		assert.is_same(progress, 4)
	end)
end)