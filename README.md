# lazylualinq

[![tests](https://github.com/Henkoglobin/lazylualinq/actions/workflows/test-and-publish.yml/badge.svg)](https://github.com/Henkoglobin/lazylualinq/actions/workflows/test-and-publish.yml) [![luarocks](https://img.shields.io/luarocks/v/henkoglobin/lazylualinq?style=plastic)](https://luarocks.org/modules/henkoglobin/lazylualinq)

LazyLuaLinq provides a simple, _lazy_ implementation of linq-like functions for Lua. With LazyLuaLinq, you can implement data transformation in elegant, expressive _queries_ akin to SQL:

```lua
local topProductsAlphabetically = from(getProducts())
    :where(function(product) return product.rating > 4.0 end)
    :orderBy(function(product) return product.name end)
    :toArray()
```

Queries are executed _lazily_, i.e. queries will only iterate their source as far as required. Consider the following (contrived) example:

```lua
local number = from { 3, 2, 1, 0 }
    :select(function(n) return 1 / n end)
    :first(function(n) return n == 1 end)
```

Without lazy evaluation, this code would result in a division by zero when calculating the last element of the sequence. Luckily, with LazyLuaLinq, this won't happen, as the second-to-last element fulfils the condition specified in the call to `first` and therefore prevents further iteration.

Check out the documentation on [Github Pages](https://henkoglobin.github.io/lazylualinq/) or get lazylualinq now on [LuaRocks](https://luarocks.org/modules/henkoglobin/lazylualinq)!

# Getting Started

In order to use lazylualinq locally, we recommend installing it from [LuaRocks](https://luarocks.org/modules/henkoglobin/lazylualinq):

```bash
# Note: Depending on your setup, you may have to run this using sudo.
luarocks install --server=https://luarocks.org/dev lazylualinq
```

Then, just `require` it from your code and start using it!

```lua
local linq = require("lazylualinq")

local seq = linq { 1, 2, 3 }
    :where(function(v) return v % 2 == 1 end)
-- seq is now equivalent to linq { 1, 3 }

```

## Developing lazylualinq

If you want to make changes to lazylualinq, you should install the test dependencies first:

```bash
sudo luarocks test --prepare
```

Then, you can run the tests using `luarocks test`. If you're not familiar with our unit testing framework _[busted](https://lunarmodules.github.io/busted/)_, now would be a great time to read up on it!

Got something that you feel is worth sharing? We'd love for you to open up a PR!

Do you want to help out, but have no idea what to work on? Check out our [issues on Github](https://github.com/Henkoglobin/lazylualinq/issues). 

## Links

- Documentation: https://henkoglobin.github.io/lazylualinq/
- LuaRocks: https://luarocks.org/modules/henkoglobin/lazylualinq
- Issues: https://github.com/Henkoglobin/lazylualinq/issues

### Further Reading

- Edulinq blog series by Jon Skeet: https://codeblog.jonskeet.uk/category/edulinq/

## License

This is free and unencumbered software released into the public domain.

Check out the full license here: https://github.com/Henkoglobin/lazylualinq/blob/main/LICENSE