-- ordering.lua
--
-- Contains functions used in the ordering functions of lazylualinq

local function getDefaultComparer()
	return function(a, b)
		if a < b then
			return -1
		elseif a == b then
			return 0
		else
			return 1
		end
	end
end

local function getProjectionComparer(selector, comparer)
	return function(a, b)
		local keyA = selector(a)
		local keyB = selector(b)

		return comparer(keyA, keyB)
	end
end

local function getReverseComparer(comparerFunc)
	return function(a, b)
		return comparerFunc(b, a)
	end
end

local function getCompoundComparer(primary, secondary)
	return function(a, b)
		local result = primary(a, b)

		if result == 0 then
			result = secondary(a, b)
		end

		return result
	end
end

local function getOrderingFactory()
	return function(me)
		local comparer = me.comparer

		local array = me.source:select(
			function(v, k)
				return { key = k, value = v }
			end)
			:toArray()

		-- Correctness first: Let Lua do the actual sorting for us :)
		table.sort(array, function(a, b) return comparer(a.value, b.value) == -1 end)

		local progress = 0

		return function()
			progress = progress + 1
			local pair = array[progress]
			if pair ~= nil then
				return pair.value, pair.key
			else
				return nil, nil
			end
		end
	end
end

return {
	getDefaultComparer = getDefaultComparer,
	getProjectionComparer = getProjectionComparer,
	getReverseComparer = getReverseComparer,
	getCompoundComparer = getCompoundComparer,
	getOrderingFactory = getOrderingFactory
}
