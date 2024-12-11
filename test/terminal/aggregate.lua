describe("terminal operator #aggregate", function()
	local linq = require("lazylualinq")

    it("uses the first value if no seed is given", function()
        local selector = spy.new(function(a, b) return a + b end)
        
        linq { 1, 2 }:aggregate(selector)

        -- The selector is only called once
        assert.spy(selector).was.called(1)
        assert.spy(selector).was.called_with(1, 2, 2)
    end)

    it("uses the seed value if it is given", function()
        local selector = spy.new(function(a, b) return a + b end)
        
        linq { 1, 2 }:aggregate(0, selector)

        -- The selector is called twice in this case
        assert.spy(selector).was.called(2)
        assert.spy(selector).was.called_with(0, 1, 1)
        assert.spy(selector).was.called_with(1, 2, 2)
    end)
end)