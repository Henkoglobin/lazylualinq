describe("configuration function #withLambdaEnv", function()
	it("allows access to the global environment if not called", function()
		local linq = require("lazylualinq")
		local func = linq.lambda("os")
		local ret = func()

		assert.is_equal(os, ret)
	end)

	it("can be used to sandbox lambdas", function()
		local linq = require("lazylualinq").withLambdaEnv({})
		local func = linq.lambda("os")

		local ret = func()

		-- os is not available within the lambda
		assert.is_nil(ret)
	end)
end)
