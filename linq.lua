local linq = {}

linq.__index = linq
setmetatable(linq, {
	__call = function(self, ...)
		return self.new(...)
	end
})

local LAMBDA_PATTERN = [[^%s*%(?(.-)%)?%s*=>%s*(.-)%s*$]]
local RETURN_PATTERN = [[%b()]]
local EMPTY_SEQUENCE	


local tablemt = { __index = table }

local function newTable()
	return setmetatable({}, tablemt)
end

local function isLinq(obj)
	return getmetatable(obj) and getmetatable(obj).__index == linq
end

local function lambda(expr)
	local args, rets = expr:match(LAMBDA_PATTERN)
	local chunk, err

	if args and rets then
		local newrets = rets:match(RETURN_PATTERN)
		if newrets == rets then
			rets = rets:sub(2, #rets - 1)
		end

		chunk, err = loadstring(
			([[return function(%s) return %s end]]):format(args, rets)
		)
	else
		chunk, err = loadstring(
			([[return function(v, k) return %s end]]):format(expr)
		)
	end

	if not chunk then
		error("Invalid lambda expression!\n" .. err, 3)
	end

	return chunk()
end

--[[
		LINQ CONSTRUCTORS
  ]]

-- General constructor (`from`). Tries to guess the user's intentions.
function linq.new(...)
	local values = {...}

	if #values == 0 then
		if not EMPTY_SEQUENCE then
			EMPTY_SEQUENCE = linq.params()
		end

		return EMPTY_SEQUENCE
	elseif #values == 1 then
		local source = values[1]

		if type(source) == "table" then
			if isLinq(source) then
				return source
			else
				if source[1] then
					return linq.array(source)
				else
					return linq.table(source)
				end
			end
		elseif type(source) == "function" then
			return linq.iterator(source)
		else
			return linq.params(...)
		end
	else
		return linq.params(...)
	end
end

-- Range constructor. Creates numbers in [start, start + count)
function linq.range(start, count)
	if type(start) ~= "number" then
		error("First argument 'start' must be a number!", 2)
	end

	if type(count) ~= "number" or count < 0 then
		error("Second argument 'count' must be a positive number!", 2)
	end

	local function factory()
		local progress = 0

		return function()
			if progress < count then
				progress = progress + 1
				return progress + start - 1, progress
			end
		end
	end

	return linq.factory(factory)
end

-- Empty constructor. Returns a (cached) empty sequence
function linq.empty()
	return linq()
end

-- Iterator constructor. Creates a Linq sequence from an iterator
-- function such as string.gmatch or io.lines.
-- The created sequence can be queried more than once (other than
-- the iterator function from which the sequence is created).
-- This is achieved by using memoization.
function linq.iterator(func)
	local values = {}
	local overall = 0

	function factory()
		local progress = 0

		return function()
			local value, index

			progress = progress + 1
			if progress > overall then
				value, index = func()
				overall = overall + 1
				values[overall] = {value = value, index = index}
			else
				value, index = values[progress].value, values[progress].index
			end

			if value then
				return value, index or progress
			end
		end
	end

	return linq.factory(factory)
end

-- Factory constructor. Returns a Linq sequence based upon a factory function.
-- When called, a factory function returns an iterator over the sequence.
-- This is the constructor that is used by all the other constructors as well
-- as other functions that return a sequence.
function linq.factory(fac)
	return setmetatable({}, { __call = fac, __index = linq })
end

-- Repeat constructor. Returns a Linq sequence that contains `value`, repeated
-- `count` times.
function linq.rep(value, count)
	if type(count) ~= "number" or count < 0 then
		error("Second argument 'count' must be a positive number!", 2)
	end

	local function factory()
		local progress = 0

		return function()
			if progress < count then
				progress = progress + 1
				return value, progress
			end
		end
	end

	return linq.factory(factory)
end

-- Parameter constructor. Returns a Linq sequence that contains all parameters
-- that are passed.
--	`linq.params(1, 2, 3)`
-- is the same as
--	`linq.array{1, 2, 3}`
-- (note the curly braces used in the second call!)
function linq.params(...)
	local values = {...}

	local function factory()
		local progress = 0
		return function()
			progress = progress + 1
			local v = values[progress]
			return v, v and progress or nil
		end
	end

	return linq.factory(factory)
end

-- Table constructor. Returns a sequence that contains **all** entries
-- in the table passed. Other than `linq.array`, the iterator of
-- the returned sequence will not follow a specific order.
function linq.table(t)
	if type(t) ~= "table" then
		error("First argument 't' must be a table!", 2)
	end

	local function factory()
		local next, tab, start = pairs(t)
		local cont = true

		return function()
			if cont then
				local key, value = next(tab, start)
				if key == nil then
					cont = false
				else
					start = key
				end

				return value, key
			else
				return nil, nil
			end
		end
	end

	return linq.factory(factory)
end

-- Array constructor. Returns a sequence that contains all entries
-- in the table passed that have a numeric index in [1, #table].
-- Iterators created from this sequence will return the entries
-- in order of the index, ascending.
function linq.array(t)
	if type(t) ~= "table" then
		error("First argument 't' must be a table!", 2)
	end

	local function factory()
		local next, tab, start = ipairs(t)

		return function()
			if start ~= nil then
				local v
				start, v = next(tab, start)
				return v, start
			else
				return nil
			end
		end
	end

	return linq.factory(factory)
end

--[[
		LINQ SEQUENCE FUNCTIONS
  ]]

-- Where function. Returns a sequence that contains all entries from the
-- source for which predicate returns true.
function linq:where(predicate)
	if type(predicate) == "string" then
		predicate = lambda(predicate)
	end

	if type(predicate) ~= "function" then
		error("First argument 'predicate' must be a function or lambda!", 2)
	end

	local function factory()
		local it = self()

		return function()
			local value, index
			repeat
				value, index = it()
			until index == nil or predicate(value, index)

			return value, index
		end
	end

	return linq.factory(factory)
end

-- Select function. Returns a sequence which is altered by the selector.
-- The selector may change the key, the value, both or neither.
function linq:select(selector)
	if type(selector) == "string" then
		selector = lambda(selector)
	end

	if type(selector) ~= "function" then
		error("First argument 'selector' must be a function or lambda!", 2)
	end

	local function factory()
		local it = self()

		return function()
			local value, index = it()

			if value ~= nil then
				local v, i = selector(value, index)
				return v, i and i or index
			end

			return nil, nil
		end
	end

	return linq.factory(factory)
end

--
function linq:selectMany(collectionSelector, resultSelector)
	if type(collectionSelector) == "string" then
		collectionSelector = lambda(collectionSelector)
	end

	if type(resultSelector) == "string" then
		resultSelector = lambda(resultSelector)
	end

	if type(collectionSelector) ~= "function" then
		error("First argument 'collectionSelector' must be a function or lambda!", 2)
	end

	if resultSelector and type(resultSelector) ~= "function" then
		error("Second argument 'resultSelector' must be a function or lambda!", 2)
	end

	local function factory()
		local outerIt = self()
		local outerValue, outerIndex
		local innerIt
		local progress = 0

		return function()
			if innerIt == nil then
				outerValue, outerIndex = outerIt()

				if outerIndex == nil then
					return nil, nil
				end

				innerIt = linq(collectionSelector(outerValue, outerIndex))()
			end

			local innerValue, innerIndex = innerIt()

			while innerIndex == nil do
				outerValue, outerIndex = outerIt()

				if outerIndex == nil then
					return nil, nil
				end

				innerIt = linq(collectionSelector(outerValue, outerIndex))()

				innerValue, innerIndex = innerIt()
			end


			if resultSelector then
				local resultValue, resultIndex = resultSelector(outerValue, outerIndex, innerValue, innerIndex)
				progress = progress + 1
				return resultValue, resultIndex or progress
			else
				return innerValue, innerIndex
			end
		end
	end

	return linq.factory(factory)
end

function linq:concat(other)
	if not isLinq(other) then
		error("First argument 'other' must be a Linq object!", 2)
	end

	local function factory()
		local it = self()
		local otherUsed = false

		return function()
			local value, index = it()
			if not index and not otherUsed then
				it = other()
				otherUsed = true
				value, index = it()
			end

			return value, index
		end
	end

	return linq.factory(factory)
end


--[[
		LINQ METAFUNCTIONS
  ]]
function linq:__index(key)
	return self:where(function(v, i) return i == key end):first()
end

function linq:__len()
	return self:count()
end

function linq:__concat(other)
	return self:concat(other)
end

--[[
		LINQ SCALAR FUNCTIONS
  ]]

-- Count function. Returns the number of entries in a sequence.
function linq:count(predicate)
	if predicate then
		if type(predicate) == "string" then
			predicate = lambda(predicate)
		end

		if type(predicate) ~= "function" then
			error("First argument 'predicate' must be a function or lambda!", 2)
		end

		local it = self()
		local count = 0

		repeat
			local value, index = it()
			if index and predicate(value, index) then
				count = count + 1
			end
		until index == nil

		return count
	else

	end
end

-- Any function. Returns true if there is an item (that matches the predicate) in the sequence.
function linq:any(predicate)
	if predicate then
		if type(predicate) == "string" then
			predicate = lambda(predicate)
		end

		if type(predicate) ~= "function" then
			error("First argument 'predicate' must be a function or lambda!", 2)
		end

		local it = self()

		repeat
			local value, index = it()
			if index and predicate(value, index) then
				return true
			end
		until index == nil

		return false
	else
		local it = self()
		local value, index = it()

		return index ~= nil
	end
end

-- All function. Returns true if all items match the predicate given.
function linq:all(predicate)
	if type(predicate) == "string" then
		predicate = lambda(predicate)
	end

	if type(predicate) ~= "function" then
		error("First argument 'predicate' must be a function of lambda!", 2)
	end

	local it = self()

	repeat
		local value, index = it()
		if index and not predicate(value, index) then
			return false
		end
	until index == nil

	return true
end

-- First function. Returns the first item in the sequence.
function linq:first(predicate)
	if predicate then
		if type(predicate) == "string" then
			predicate = lambda(predicate)
		end

		if type(predicate) ~= "function" then
			error("First argument 'predicate' must be a function or lambda!", 2)
		end

		local it = self()

		repeat
			local value, index = it
			if index and predicate(value, index) then
				return value, index
			end
		until index == nil

		error("No items matched the predicate!", 2)
	else
		local it = self()
		local value, index = it()

		if index ~= nil then
			return value, index
		end

		error("Sequence was empty!", 2)
	end
end

function linq:firstOr(predicate, defaultValue, defaultIndex)
	local ok, value, index = pcall(self.first, self, predicate)

	if ok then
		return value, index
	else
		return defaultValue, defaultIndex
	end
end


-- Single function. Returns the one and only item (that matches the predicate) in the sequence.
-- Throws an error if there are multiple (matching) items.
function linq:single(predicate)
	if predicate then
		if type(predicate) == "string" then
			predicate = lambda(predicate)
		end

		if type(predicate) ~= "function" then
			error("First argument 'predicate' must be a function or lambda!", 2)
		end

		local it = self()
		local foundVal, foundIndex

		repeat
			local value, index = it()
			if index and predicate(value, index) then
				if foundIndex then
					error("Sequence contained multiple matching elements!", 2)
				end
				foundVal, foundIndex = value, index
			end
		until index == nil

		if foundIndex == nil then
			error("No items matched the predicate!", 2)
		end

		return foundVal, foundIndex
	else
		local it = self()
		local retVal, retIndex = it()

		if retIndex == nil then
			error("Sequence was empty!", 2)
		end

		local val2, index2 = it()

		if index2 ~= nil then
			error("Sequence contained multiple elements!", 2)
		end

		return retVal, retIndex
	end
end


-- ToArray function. Returns a table with all the entries of a sequence.
-- This ignores the indices returned by the sequence and creates a
-- numerical indixed table.
function linq:toArray()
	local it = self()
	local t = newTable()

	repeat
		local value, index = it()
		if index then
			table.insert(t, value)
		end
	until index == nil

	return t
end

-- ToTable function. Returns a table with all the entries of a sequence.
-- This uses the indices provided by the sequence. If two or more entries
-- have the same index, only the last one will be in the resulting table.
function linq:toTable()
	local it = self()
	local t = newTable()

	repeat
		local value, index = it()
		if index then
			t[index] = value
		end
	until index == nil

	return t
end

-- Calls the provided function for every entry in a sequence.
-- Other than with all other functions, the function will
-- receive the index first. This allows for a quite pretty output
-- using :foreach(print). If this behaviour is not desired,
-- use :select(print).
function linq:foreach(func)
	if type(func) ~= "function" then
		error("First argument 'func' must be a function!", 2)
	end

	local it = self()

	repeat
		local value, index = it()

		if index ~= nil then
			func(index, value)
		end
	until index == nil
end

return linq
