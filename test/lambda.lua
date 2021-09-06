describe("lambda", function()
    insulate("requires load or loadstring", function()
        local loadBackup, loadstringBackup = load, loadstring
    
        it("does not work without load or loadstring", function()
            _G.load, _G.loadstring = nil, nil

            local linq = require("linq")
    
            assert.has_error(function() 
                local func = linq.lambda("a => a")
            end) 
        end)

        it("#meta restore globals", function() 
            -- Due to a bug in busted's insulation, we need to explicitely recover the values
            -- of these globals at the end of the insulation block
            -- See https://github.com/Olivine-Labs/busted/issues/666 for details
            _G.load, _G.loadstring = loadBackup, loadstringBackup
        end)
    end)

    it("reports invalid #expressions", function()
        local linq = require("linq")

        assert.has_error(function() linq.lambda("?") end)
    end)

    describe("with explicit parameter definition", function()
        local linq = require("linq")

        it("should compile a simple lambda", function()
            local func = linq.lambda("a => a * 2")
    
            assert.is_function(func)
            assert.is_same(func(2), 4)
        end)

        it("can have any number of parameters", function()
            local func = linq.lambda("a, b, c, d, e => a + 2*b + 3*c + 4*d + 5*e")
            local info = debug.getinfo(func)

            assert.is_function(func)
            assert.is_same(func(1, 1, 1, 1, 1), 15)

            assert.is_same(info.nparams, 5)
        end)

        it("can have zero parameters", function()
            local func = linq.lambda("() => 3")

            assert.is_function(func)
            assert.is_same(func(), 3)
        end)

        it("can have a variable number of parameters", function()
            local func = linq.lambda("... => #{...}")
            local info = debug.getinfo(func)

            assert.is_true(info.isvararg)
            assert.is_same(func(1), 1, "function should return number of parameters passed")
            assert.is_same(func(1, 2), 2, "function should return number of parameters passed")
            assert.is_same(func(0, 0, 0), 3, "function should return number of parameters passed")
        end)

        it("can have parameters enclosed in parantheses", function()
            local func = linq.lambda("(a, b) => a + 3 * b")

            assert.is_function(func)
            assert.is_same(func(1, 2), 7)
        end)

        it("can have return values enclosed in parantheses", function()
            local func = linq.lambda("(a, b) => (b, a)")

            assert.is_function(func)
            local a, b = func(2, 1)

            assert.is_same(a, 1)
            assert.is_same(b, 2)
        end)
    end)

    describe("with anonymous parameters", function()
        local linq = require("linq")

        it("compiles successfully", function()
            local func = linq.lambda("v * 3")
    
            assert.is_function(func)
            assert.is_same(func(4), 12)
        end)

        it("supports parameters v and k, in that order.", function()
            local func = linq.lambda("v + 3 * k")

            assert.is_function(func)
            assert.is_same(func(1, 2), 7, "1 + 3 * 2 = 7")
        end)

        it("has exactly two anonymous parameters", function()
            local func = linq.lambda("v * 2")
            local info = debug.getinfo(func)

            assert.is_same(info.nparams, 2, "only two parameters are defined")
            assert.is_false(info.isvararg)
        end)
    end)
end)