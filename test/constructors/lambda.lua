describe("#lambda", function()
	local major, minor = _VERSION:match("Lua (%d)%.(%d)")
	local major, minor = tonumber(major), tonumber(minor)
	local extendedDebugInfoAvailable = major > 5 or (major == 5 and minor >= 2)

	insulate("requires load or loadstring", function()
		it("does not work without load or loadstring", function()
			_G.load, _G.loadstring = nil, nil

			local linq = require("lazylualinq")
	
			assert.has_error(function() 
				local func = linq.lambda("a => a")
			end) 
		end)
	end)

	it("reports invalid #expressions", function()
		local linq = require("lazylualinq")

		assert.has_error(function() linq.lambda("?") end)
	end)

	describe("with explicit parameter definition", function()
		local linq = require("lazylualinq")

		it("should compile a simple lambda", function()
			local func = linq.lambda("a => a * 2")
	
			assert.is_function(func)
			assert.is_same(4, func(2))
		end)

		it("can have any number of parameters", function()
			local func = linq.lambda("a, b, c, d, e => a + 2*b + 3*c + 4*d + 5*e")

			assert.is_function(func)
			assert.is_same(15, func(1, 1, 1, 1, 1))

			if not extendedDebugInfoAvailable then
				return
			end

			local info = debug.getinfo(func)
			assert.is_same(5, info.nparams)
		end)

		it("can have zero parameters", function()
			local func = linq.lambda("() => 3")

			assert.is_function(func)
			assert.is_same(3, func())
		end)

		it("can have a variable number of parameters", function()
			local func = linq.lambda("... => #{...}")

			
			assert.is_same(1, func(1), "function should return number of parameters passed")
			assert.is_same(2, func(1, 2), "function should return number of parameters passed")
			assert.is_same(3, func(0, 0, 0), "function should return number of parameters passed")


			if not extendedDebugInfoAvailable then
				return
			end

			local info = debug.getinfo(func)
			assert.is_true(info.isvararg)
		end)

		it("can have parameters enclosed in parantheses", function()
			local func = linq.lambda("(a, b) => a + 3 * b")

			assert.is_function(func)
			assert.is_same(7, func(1, 2))
		end)

		it("can have return values enclosed in parantheses", function()
			local func = linq.lambda("(a, b) => (b, a)")

			assert.is_function(func)
			local a, b = func(2, 1)

			assert.is_same(1, a)
			assert.is_same(2, b)
		end)
	end)

	describe("with anonymous parameters", function()
		local linq = require("lazylualinq")

		it("compiles successfully", function()
			local func = linq.lambda("v * 3")
	
			assert.is_function(func)
			assert.is_same(12, func(4))
		end)

		it("supports parameters v and k, in that order.", function()
			local func = linq.lambda("v + 3 * k")

			assert.is_function(func)
			assert.is_same(7, func(1, 2), "1 + 3 * 2 = 7")
		end)

		it("has exactly two anonymous parameters", function()
			local func = linq.lambda("v * 2")

			if not extendedDebugInfoAvailable then
				return
			end

			local info = debug.getinfo(func)

			assert.is_same(info.nparams, 2, "only two parameters are defined")
			assert.is_false(info.isvararg)
		end)
	end)
end)