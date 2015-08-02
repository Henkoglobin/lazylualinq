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

local function getReverseComparer(comparerFunc)
	return function(a, b)
		return comparerFunc(b, a)
	end
end

local function getCompositeSelector(primarySelector, secondarySelector)
	return function(element)
		return {
			primary = primarySelector(element),
			secondary = secondarySelector(element)
		}
	end
end

local function getCompositeComparer(primaryComparer, secondaryComparer)
	return function(a, b)
		local primaryResult = primaryComparer(a.primary, b.primary)

		if primaryResult ~= 0 then 
			return primaryResult 
		end

		return secondaryComparer(a.secondary, b.secondary)
	end
end

local function getOrderingFactory()
	return function(me)
		local comparer = me.comparer
		local selector = me.selector

		local array = me.source:select(
			function(v, k)
				return { key = k, value = v, compositeKey = me.selector(v) }
			end)
			:toArray()

		-- Correctness first: Let Lua do the actual sorting for us :)
		table.sort(array, function(a, b) return comparer(a.compositeKey, b.compositeKey) == -1 end)

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
	getReverseComparer = getReverseComparer,
	getOrderingFactory = getOrderingFactory,
	getCompositeComparer = getCompositeComparer,
	getCompositeSelector = getCompositeSelector
}
