describe("#configuration function disableLambdas", function()
	it("disallows the use of lambdas", function()
		local linq = require("lazylualinq").disableLambdas()
		local seq = linq {1, 2, 3}

		assert.has_error(function()
			seq:select("v => v * 2")
		end, "Lambdas have been disabled")
	end)

	it("disables linq.lambda", function()
		local linq = require("lazylualinq").disableLambdas()
		
		assert.has_error(function()
			linq.lambda("v => v * 2")
		end, "Lambdas have been disabled")
	end)

	-- It could be nice to allow this (though we'd likely want lambdas disabled by default then).
	-- For the moment, though, this is how it is.
	-- If we allow multiple different configurations, though, we'd need the module to return a kind of 'module factory'
	-- (which would force users to do something like `local linq = require("lazylualinq").build()`)
	it("disables lambdas globally", function()
		local linq = require("lazylualinq").disableLambdas()
		local safeLinq = require("lazylualinq")

		assert.has_error(function()
			safeLinq.lambda("v => v * 2")
		end, "Lambdas have been disabled")
	end)
end)
