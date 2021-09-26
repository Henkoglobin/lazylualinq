local say = require("say")
local assert = require("luassert")
local util = require("luassert.util")

local function any_of(state, arguments)
    local actual = arguments[1]
    local expected = arguments[2]

    for _, v in pairs(expected) do
        if util.deepcompare(actual, v, true) then
            return true
        end
    end

    return false
end

local function fail(state, arguments)
    state.failure_message = arguments[1] or "Test failed"
    return false
end

say:set("assertion.any_of.positive", "Expected %s to be any of %s")
say:set("assertion.any_of.negative", "Expected %s to be neither of %s")

assert:register("assertion", "any_of", any_of, "assertion.any_of.positive", "assertion.any_of.negative")
assert:register("assertion", "fail", fail, nil, nil)
