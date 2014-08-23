lazylualinq
===========

An implementation of linq-like functions for lua

String Lambdas
--------------

LazyLuaLinq supports string lambdas as a short-hand form of anonymous functions. Whenever a function accepts a function (e.g. a predicate or a transformation), you may also pass a string instead. For example, the following two snippets are identical:

```lua
local sequence = linq.range(1, 10)
sequence:where(function(x) return x % 2 == 0 end):foreach(print)
```

```lua
local sequence = linq.range(1, 10)
sequence:where("v % 2 == 0"):foreach(print)
```

There are two ways to specify a string lambda. The first form, which can be seen above, only specifies the return value(s). The function parameters can be accessed with the variables k (the key of the sequence) and v (the corresponding value). If you want to specify names for the parameters for clarity, you may use the lambda syntax: `(v, k) => v % 2 == 0`.

Note that: 

1. Parameters are always passed in the order value, key (except for the foreach operator).
2. You may specify any number of parameters for a lambda function. However, only two parameters will ever be passed (except for selectMany). As is common for Lua, you may specify less parameters than are actually passed.
3. If you do not need to specify parameter names, you can omit the first part of the string lambda as seen above.

Supported Operators
-------------------

