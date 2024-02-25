describe("intermediate operator '#uniqueBy'", function()
    local linq = require("lazylualinq")

    it("returns the first match, but no further matches", function()
        local iterator = linq {
                { author = "Brandon Sanderson", title = "The Way of Kings" },
                { author = "Brandon Sanderson", title = "Words of Radiance" },
                { author = "Brandon Sanderson", title = "Oathbringer" },
                { author = "Brandon Sanderson", title = "The Rhythm of War" },
                { author = "Patrick Rothfuss", title = "The Name of the Wind" },
                { author = "Patrick Rothfuss", title = "The Wise Man's Fear" },
            }
            :uniqueBy(function(v) return v.author end)
            :getIterator()
        
        assert.is_same(
            { { author = "Brandon Sanderson", title = "The Way of Kings" }, 1 }, 
            { iterator() }
        )
        assert.is_same(
            { { author = "Patrick Rothfuss", title = "The Name of the Wind" }, 5 }, 
            { iterator() }
        )
    end)

    it("stops on the first nil index", function()
        local iterator = linq { "a", "bb", "ccc" }
            :uniqueBy(function(v) return #v end)
            :getIterator()

            assert.is_same({ "a"  , 1 }, { iterator() })
            assert.is_same({ "bb" , 2 }, { iterator() })
            assert.is_same({ "ccc", 3 }, { iterator() })
            assert.is_same({ nil  , nil }, { iterator() })
    end)
end)