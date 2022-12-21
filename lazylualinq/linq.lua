local ordering = require("lazylualinq.ordering")

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

function linq.isLinq(obj)
	return getmetatable(obj) and getmetatable(obj).__index == linq
end

local loadstring = loadstring or load or function()
	error("Neither loadstring nor load are defined!")
end

function linq.lambda(expr)
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
		error("Invalid lambda expression!" .. err, 3)
	end

	return chunk()
end

--[[
		LINQ CONSTRUCTORS
  ]]

function linq.from(...)
	return linq.new(...)
end

-- General constructor (`from`). Tries to guess the user's intentions.
function linq.new(...)
	local values = {...}

	if #values == 0 then
		return linq.empty()
	elseif #values == 1 then
		local source = values[1]

		if type(source) == "table" then
			if linq.isLinq(source) then
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
		end
	end

	return linq.params(...)
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
	if not EMPTY_SEQUENCE then
		EMPTY_SEQUENCE = linq.params()
	end

	return EMPTY_SEQUENCE
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
	return setmetatable({}, { 
		__call = fac, 
		__index = linq,
		__len = function(self) 
			return self:count()
		end,
		__concat = function(self, other)
			return self:concat(other)
		end,
		__pairs = function(self)
			return function(it)
				local v, k = it()
				return k, v
			end, self:getIterator(), nil
		end,
	})
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
		predicate = linq.lambda(predicate)
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
		selector = linq.lambda(selector)
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

-- SelectMany function. 
function linq:selectMany(collectionSelector, resultSelector)
	if type(collectionSelector) == "string" then
		collectionSelector = linq.lambda(collectionSelector)
	end

	if type(resultSelector) == "string" then
		resultSelector = linq.lambda(resultSelector)
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

function linq:batch(size)
	if type(size) ~= "number" or size < 1 then
		error("First argument 'size' must be a positive number", 2)
	end

	local function factory()
		local it = self()
		local progress = 0
		local done = false

		return function()
			if done then
				return nil, nil
			end

			local currentBatch = {}
			progress = progress + 1

			local value, index = it()
			while index ~= nil do
				table.insert(currentBatch, { value, index })

				if #currentBatch < size then
					value, index = it()
				else
					break
				end
			end

			if index == nil then
				done = true

				if #currentBatch == 0 then
					return nil, nil
				end
			end

			return currentBatch, progress
		end
	end

	return linq.factory(factory)
end

function linq:batchValues(size)
	if type(size) ~= "number" or size < 1 then
		error("First argument 'size' must be a positive number", 2)
	end

	local function factory()
		local it = self()
		local progress = 0
		local done = false

		return function()
			if done then
				return nil, nil
			end

			local currentBatch = {}
			progress = progress + 1

			local value, index = it()
			while index ~= nil do
				table.insert(currentBatch, value)

				if #currentBatch < size then
					value, index = it()
				else
					break
				end
			end

			if index == nil then
				done = true

				if #currentBatch == 0 then
					return nil, nil
				end
			end

			return currentBatch, progress
		end
	end

	return linq.factory(factory)
end

function linq:windowed(size)
	if type(size) ~= "number" or size < 1 then
		error("First argument 'size' must be a positive number", 2)
	end

	local function factory()
		local it = self()
		local progress = 0
		local done = false
		local window = {}

		return function()
			progress = progress + 1
			repeat
				local value, index = it()

				if index == nil then
					return nil, nil
				end

				table.insert(window, value)
			until #window == size

			local ret = window
			window = linq.from(window):skip(1):toArray()
			
			return ret, progress
		end
	end

	return linq.factory(factory)
end

function linq:orderBy(selector, comparer)
	if type(selector) == "string" then
		selector = linq.lambda(selector)
	end

	if type(selector) ~= "function" then
		error("First argument 'selector' must be a function or lambda!", 2)
	end

	if type(comparer) == "string" then
		comparer = linq.lambda(comparer)
	end

	if comparer ~= nil and type(comparer) ~= "function" then
		error("Second argument 'comparer' must be a function or lambda, if provided!", 2)
	end

	local result = linq.factory(ordering.getOrderingFactory(self))

	result.source = self
	result.comparer = comparer or ordering.getDefaultComparer()
	result.selector = selector

	return result
end

function linq:orderByDescending(selector, comparer)
	if type(selector) == "string" then
		selector = linq.lambda(selector)
	end

	if type(selector) ~= "function" then
		error("First argument 'selector' must be a function or lambda!", 2)
	end

	if type(comparer) == "string" then
		comparer = linq.lambda(comparer)
	end

	if comparer ~= nil and type(comparer) ~= "function" then
		error("Second argument 'comparer' must be a function or lambda, if provided!", 2)
	end

	local result = linq.factory(ordering.getOrderingFactory(self))

	result.source = self
	local innerComparer = comparer or ordering.getDefaultComparer()
	result.comparer = ordering.getReverseComparer(innerComparer)
	result.selector = selector

	return result
end

function linq:thenBy(selector, comparer)
	if self.source == nil or self.comparer == nil or self.selector == nil then
		error("Cannot add a second ordering to an unordered sequence!", 2)
	end

	if type(selector) == "string" then
		selector = linq.lambda(selector)
	end

	if type(selector) ~= "function" then
		error("First argument 'selector' must be a function or lambda!", 2)
	end

	if type(comparer) == "string" then
		comparer = linq.lambda(comparer)
	end

	if comparer ~= nil and type(comparer) ~= "function" then
		error("Second argument 'comparer' must be a function or lambda, if provided!", 2)
	end

	local result = linq.factory(ordering.getOrderingFactory())

	result.source = self.source
	local innerComparer = comparer or ordering.getDefaultComparer()
	result.comparer = ordering.getCompositeComparer(self.comparer, innerComparer)
	result.selector = ordering.getCompositeSelector(self.selector, selector)

	return result
end

function linq:thenByDescending(selector, comparer)
	if self.source == nil or self.comparer == nil or self.selector == nil then
		error("Cannot add a second ordering to an unordered sequence!", 2)
	end

	if type(selector) == "string" then
		selector = linq.lambda(selector)
	end

	if type(selector) ~= "function" then
		error("First argument 'selector' must be a function or lambda!", 2)
	end

	if type(comparer) == "string" then
		comparer = linq.lambda(comparer)
	end

	if comparer ~= nil and type(comparer) ~= "function" then
		error("Second argument 'comparer' must be a function or lambda, if provided!", 2)
	end

	local result = linq.factory(ordering.getOrderingFactory())

	result.source = self.source
	local innerComparer = comparer or ordering.getDefaultComparer()
	local reverseComparer = ordering.getReverseComparer(innerComparer)
	result.comparer = ordering.getCompositeComparer(self.comparer, reverseComparer)
	result.selector = ordering.getCompositeSelector(self.selector, selector)

	return result
end

function linq:unique()
	return self:uniqueBy(function(x) return x end)
end

function linq:uniqueBy(selector)
	if type(selector) == "string" then
		selector = linq.lambda(selector)
	end

	local function factory()
		local it = self()
		local seen = {}

		return function()
			local value, index, key
			repeat
				value, index = it()
				key = selector(value)
			until index == nil or not seen[key]

			if key ~= nil then
				seen[key] = true
			end

			return value, index
		end
	end

	return linq.factory(factory)
end

function linq:skip(count)
	if type(count) ~= "number" or count < 0 then
		error("First argument 'count' must be a positive number!", 2)
	end

	local function factory()
		local it = self()
		local progress = 0

		return function()
			while progress < count do
				local value, index = it()
				progress = progress + 1

				if index == nil then
					return
				end
			end

			return it()
		end
	end

	return linq.factory(factory)
end

function linq:take(count)
	if type(count) ~= "number" or count < 0 then
		error("First argument 'count' must be a positive number!", 2)
	end

	local function factory()
		local it = self()
		local progress = 0
		local done = false

		return function()
			if done or progress >= count then
				return nil, nil
			end

			progress = progress + 1
			local value, index = it()

			if index == nil then
				done = true
			end

			return value, index
		end
	end

	return linq.factory(factory)
end

function linq:zip(other, resultSelector)
	if not linq.isLinq(other) then
		error("First argument 'other' must be a Linq object!", 2)
	end

	if type(resultSelector) == "string" then
		resultSelector = linq.lambda(resultSelector)
	end

	if type(resultSelector) ~= "function" then
		error("Second argument 'resultSelector' must be a function or lambda!", 2)
	end

	local function factory()
		local it1 = self()
		local it2 = other()
		local progress = 0

		return function()
			local value1, index1 = it1()
			local value2, index2 = it2()

			if index1 == nil or index2 == nil then
				return
			end

			local resultValue, resultIndex = resultSelector(value1, index1, value2, index2)
			progress = progress + 1

			return resultValue, resultIndex or progress
		end
	end

	return linq.factory(factory)
end

-- DefaultIfEmpty function. Returns a single default value if the sequence does
-- not contain any values.
function linq:defaultIfEmpty(defaultValue, defaultIndex)
	local function factory()
		local it = self()
		local returned = false
		local foundAny = false

		return function()
			local value, index = it()
			if index ~= nil then
				foundAny = true
				returned = true
				return value, index
			end

			if not foundAny or not returned then
				returned = true
				return defaultValue, defaultIndex or 1
			end
		end
	end

	return linq.factory(factory)
end

-- Reindex function. Normalizes the indices of the sequence to be purely numerical.
function linq:reindex()
	local function factory()
		local it = self()
		local index = 0
		
		return function()
			local value = it()
			
			if value ~= nil then
				index = index + 1
				return value, index
			end
		end
	end
	
	return linq.factory(factory)
end

-- NonNil function. Filters the sequence such that it only contains 
-- non-nil values.
function linq:nonNil()
	local function factory()
		local it = self()
		
		return function()
			local value, index
			
			repeat
				value, index = it()
			until index == nil or value ~= nil
			
			return value, index
		end
	end
	
	return linq.factory(factory)
end

-- Concat function. Concatenates two sequences.
function linq:concat(other)
	if not linq.isLinq(other) then
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
		LINQ SCALAR FUNCTIONS
  ]]

function linq:aggregate(seed, selector)
	local NULL = {}
	if seed and not selector then
		seed, selector = NULL, seed
	end
	
	if type(selector) == "string" then
		selector = linq.lambda(selector)
	end
	
	if type(selector) ~= "function" then
		error("Parameter 'selector' must be a function or lambda!", 2)
	end
	
	local it = self()
	repeat
		local value, index = it()
		
		if index then
			if seed == NULL then
				seed = value
			else
				seed = selector(seed, value)
			end
		end
	until index == nil
	
	return seed
end

-- Count function. Returns the number of entries in a sequence.
function linq:count(predicate)
	if predicate then
		if type(predicate) == "string" then
			predicate = linq.lambda(predicate)
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
		local it = self()
		local count = 0

		repeat
			local value, index = it()
			if index then
				count = count + 1
			end
		until index == nil

		return count
	end
end

function linq:sum(selector)
	selector = selector or function(v, k) return v end

	if type(selector) == "string" then
		selector = linq.lambda(selector)
	end

	if type(selector) ~= "function" then
		error("First argument 'selector' must be a function or lambda, if given!", 2)
	end

	local it = self()
	local result = 0

	repeat
		local value, index = it()
		if index then
			result = result + selector(value, index)
		end
	until index == nil

	return result
end

function linq:max(selector)
	selector = selector or function(v, k) return v end
	
	if type(selector) == "string" then
		selector = linq.lambda(selector)
	end
	
	if type(selector) ~= "function" then
		error("First argument 'selector' must be a function or lambda, if given!", 2)
	end
	
	return self:aggregate(function(seed, value) return math.max(seed, selector(value)) end)
end

function linq:min(selector)
	selector = selector or function(v, k) return v end
	
	if type(selector) == "string" then
		selector = linq.lambda(selector)
	end
	
	if type(selector) ~= "function" then
		error("First argument 'selector' must be a function or lambda, if given!", 2)
	end
	
	return self:aggregate(function(seed, value) return math.min(seed, selector(value)) end)
end

-- Any function. Returns true if there is an item (that matches the predicate) in the sequence.
function linq:any(predicate)
	if predicate then
		if type(predicate) == "string" then
			predicate = linq.lambda(predicate)
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
		predicate = linq.lambda(predicate)
	end

	if type(predicate) ~= "function" then
		error("First argument 'predicate' must be a function or lambda!", 2)
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
			predicate = linq.lambda(predicate)
		end

		if type(predicate) ~= "function" then
			error("First argument 'predicate' must be a function or lambda!", 2)
		end

		local it = self()

		repeat
			local value, index = it()
			if index ~= nil and predicate(value, index) then
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

-- FirstOrDefault function. Returns the first item (that matches the predicate) or the default values.
function linq:firstOr(predicate, defaultValue, defaultIndex)
	-- Validate arguments: If only two arguments were passed, the predicate is empty.
	if predicate ~= nil and defaultValue ~= nil and defaultIndex == nil then
		defaultValue, defaultIndex = predicate, defaultValue
		predicate = nil
	end

	if type(predicate) == "string" then
		predicate = linq.lambda(predicate)
	end

	if predicate and type(predicate) ~= "function" then
		error("First argument 'predicate' must be a function or lambda!", 2)
	end

	-- Call first and catch any errors
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
			predicate = linq.lambda(predicate)
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

-- SingleOrDefault function. Returns the one and only item (that matches the predicate) or the default values.
-- Throws an error if there are multiple (matching) items.
function linq:singleOr(predicate, defaultValue, defaultIndex)
	-- Check if only two parameters (in this case, defaultValue and defaultIndex) were passed
	if predicate ~= nil and defaultValue ~= nil and defaultIndex == nil then
		defaultValue, defaultIndex = predicate, defaultValue
		predicate = nil
	end

	if predicate then
		if type(predicate) == "string" then
			predicate = linq.lambda(predicate)
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
			return defaultValue, defaultIndex
		end

		return foundVal, foundIndex
	else
		local it = self()
		local value, index = it()

		if index == nil then
			return defaultValue, defaultIndex
		end

		local value2, index2 = it()
		if index2 ~= nil then
			error("Sequence contained multiple elements!", 2)
		end

		return value, index
	end
end

-- Last function. Returns the last item (that matches the predicate).
function linq:last(predicate)
	if predicate ~= nil then
		if type(predicate) == "string" then
			predicate = linq.lambda(predicate)
		end

		if type(predicate) ~= "function" then
			error("First argument 'predicate' must be a function or lambda!", 2)
		end

		local it = self()
		local foundAny = false
		local foundValue, foundIndex

		repeat
			local value, index = it()

			if index ~= nil and predicate(value, index) then
				foundAny = true
				foundValue, foundIndex = value, index
			end
		until index == nil

		if foundAny then
			return foundValue, foundIndex
		end

		error("No items matched the predicate!", 2)
	else
		local it = self()

		local value, index = it()

		if index == nil then
			error("Sequence was empty!", 2)
		end

		while index ~= nil do
			value, index = it()
		end

		return value, index
	end
end

-- LastOrDefault function. Returns the last item (that matches the predicate) or the default values.
function linq:lastOr(predicate, defaultValue, defaultIndex)
	if predicate ~= nil and defaultValue ~= nil and defaultIndex == nil then
		defaultValue, defaultIndex = predicate, defaultValue
		predicate = nil
	end

	if type(predicate) == "string" then
		predicate = linq.lambda(predicate)
	end

	if predicate and type(predicate) ~= "function" then
		error("First argument 'predicate' must be a function or lambda!", 2)
	end

	local ok, value, index = pcall(self.last, self, predicate)

	if ok then
		return value, index
	else
		return defaultValue, defaultIndex
	end
end

-- sequenceEquals function. Compares two sequences value-by-value.
function linq:sequenceEquals(other, comparer)
	if comparer == nil then
		comparer = function(a, b) return a == b end
	end

	if type(comparer) == "string" then
		comparer = linq.lambda(comparer)
	end
	
	if type(comparer) ~= "function" then
		error("Second argument 'comparer' must be a function or lambda!", 2)
	end

	other = linq(other)
	
	local it1 = self()
	local it2 = other()
	
	local value1, index1
	local value2, index2
	
	repeat
		value1, index1 = it1()
		value2, index2 = it2()
		
		if not comparer(value1, value2) then
			return false
		end
	until index1 == nil or index2 == nil
	
	return index1 == index2
end

-- ToArray function. Returns a table with all the entries of a sequence.
-- This ignores the indices returned by the sequence and creates a
-- numerical indixed table.
function linq:toArray()
	local it = self()
	local t = newTable()
	local progress = 0

	repeat
		local value, index = it()
		if index then
			progress = progress + 1
			t[progress] = value
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

-- Syntax salt for a call to a sequence.
-- Useful when iterating over a sequence:
--	 `for val, idx in from(something):where(...):getIterator() do`
-- This is more expressive than the alternative:
--	 `for val, idx in from(something):where(...)() do`
function linq:getIterator()
	return self()
end

-- Calls the provided function for every entry in a sequence.
-- Other than with all other functions, the function will
-- receive the index first. This allows for a quite pretty output
-- using :foreach(print). If this behaviour is not desired,
-- use :select(print).
function linq:foreach(func)
	if type(func) == "string" then
		func = linq.lambda(func)
	end

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

-- Convenience method aliases
linq.map = linq.select
linq.filter = linq.where
linq.flatMap = linq.selectMany

-- Allow calling :pairs() as an alias to the standard library's pairs(...)
linq.pairs = pairs

return linq
