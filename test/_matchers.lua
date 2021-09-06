local say = require("say")
local util = require("luassert.util")
local assert = require("luassert")

local function any_of(state, arguments)
    local actual = arguments[1]
    local expected = arguments[2]

    for _, v in pairs(expected) do
        if(util.deepcompare(actual, v, true)) then
            return true
        end
    end

    return false
end

say:set("assertion.any_of.positive", "Expected %s to be any of %s")
say:set("assertion.any_of.negative", "Expected %s to be neither of %s")

assert:register("assertion", "any_of", any_of, "assertion.any_of.positive", "assertion.any_of.negative")