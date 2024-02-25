describe("metamethod '__pairs'", function()
	local linq = require("lazylualinq")

	local major, minor = _VERSION:match("Lua (%d).(%d)")
	local major, minor = tonumber(major), tonumber(minor)
	local pairsMetamethodAvailable = major > 5 or (major == 5 and minor >= 2)

	it("allows iterating with for ... in pairs()", function()
		if not pairsMetamethodAvailable then
			pending("__pairs is not available in Lua 5.1 and earlier.")
			return
		end

		local items = { "a", "b", "c", "d" }

		local sequence = linq(items)
		local count = 0

		-- This is obviously a bit contrived (why would we do this?), but it shows off the functionality
		for k, v in pairs(sequence) do
			count = count + 1

			assert.is_same(count, k)
			assert.is_same(items[count], v)
		end

		-- Assert that we actually iterated the whole table
		assert.is_same(4, count)
	end)

	it("works with intermediate operators", function()
		if not pairsMetamethodAvailable then
			pending("__pairs is not available in Lua 5.1 and earlier.")
			return
		end

		local books = {
			{ author = "Brandon Sanderson", title = "The Final Empire" },
			{ author = "Brandon Sanderson", title = "The Well of Ascension" },
			{ author = "Brandon Sanderson", title = "The Hero of Ages" },
			{ author = "Patrick Rothfuss", title = "The Name of the Wind" },
			{ author = "Patrick Rothfuss", title = "The Wise Man's Fear" },
		}

		local count = 0

		for _, book in pairs(linq(books):where(function(book) return book.author == "Patrick Rothfuss" end)) do
			count = count + 1

			-- We're skipping the first three books, so add 3 to the index to compensate
			assert.is_same(books[count + 3].title, book.title)
		end

		-- Assert that we actually iterated all results
		assert.is_same(2, count)
	end)

	it("can also be called as :pairs()", function()
		if not pairsMetamethodAvailable then
			pending("__pairs is not available in Lua 5.1 and earlier.")
			return
		end

		local books = {
			{ author = "Brandon Sanderson", title = "The Final Empire" },
			{ author = "Brandon Sanderson", title = "The Well of Ascension" },
			{ author = "Brandon Sanderson", title = "The Hero of Ages" },
			{ author = "Patrick Rothfuss", title = "The Name of the Wind" },
			{ author = "Patrick Rothfuss", title = "The Wise Man's Fear" },
		}

		local count = 0

		for _, book in linq(books)
			:where(function(book) return book.author == "Patrick Rothfuss" end)
			:pairs() 
		do
			count = count + 1

			-- We're skipping the first three books, so add 3 to the index to compensate
			assert.is_same(books[count + 3].title, book.title)
		end

		-- Assert that we actually iterated all results
		assert.is_same(2, count)
	end)
end)