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

# Overview

- [Basic Concepts](#basic-concepts)
- [String Lambdas](#string-lambdas)
- [Supported Operators](#constructors)
    - [Constructors](#constructors)
    - [Intermediate Functions](#intermediate-functions)
    - [Terminal Functions](#terminal-functions)
    - [Metafunctions](#metafunctions)
    - [String Lambdas](#string-lambdas)
- [Module Configuration](#module-configuration)

# Basic Concepts

In order to understand how to effectively work with LazyLuaLinq, you should at least be somewhat familiar with the following terminology.

- __`linq`__. While you can use any name you wish to import the LazyLuaLinq module (via `local linq = require("lazylualinq")`), we'll assume that the name used is `linq`.
- __Sequences__. All operations that LazyLuaLinq implements are performed on sequences. If you're familiar with C#'s Linq, a sequence is functionally equivalent to an `IEnumerable<T>` (or Java's `Stream<T>`). This document may refer to sequences by other names, such as `streams` or `iterables`.
    - As an implementation detail, _sequences_ in LazyLuaLinq are just (usually) empty tables with a metatable whose `__index` is set to `linq`. If you need to check whether `something` is a sequence, you can conveniently use `linq.isLinq(something)` for that, so you should never really have to inspect the metatable yourself.
- __Lazy evaluation__. LazyLuaLinq will iterate sequences _lazily_, i.e. it will only advance on a sequence if strictly necessary. Note that some operators do require full evaluation of the whole sequence.
- __String Lambdas__. LazyLuaLinq makes heavy use of anonymous functions, as they are required to pass transformation logic to the operators. Some languages, such as C#, have a shorter form to specify simple anonymous functions, called lambdas: 

    ```c#
    var topProducts = products.Where(p => p.Rating >= 4.0);
    ```

    While Lua lacks a lambda syntax, LazyLuaLinq implements _string lambdas_ to allow for shorter definition of anonymous functions, using strings:

    ```lua
    local topProducts = from(products):where("p => p.rating >= 4.0")
    ```

    To learn more about this feature, check out [String Lambdas](#string-lambdas).

There are three major categories of functions (or operators) in lazylualinq: Constructors (functions that create a sequence of values from some kind of source), intermediate functions (that perform some kind of transformative operation on a sequence, such as filtering or projections) and terminal functions (which also perform a transformative operation on a sequence, but return a value that's _not_ a sequence). 

# Constructors

Constructors are methods that produce a sequence of values on which other operations can then be performed. 

## `linq.new(...)`

`linq.new(...)`, also available simply as `linq(...)` or `linq.from(...)`. This constructor _guesses_ the caller's intentions based on the number and types of parameters passed. 

- If no parameters are passed, this returns an empty sequence (see `linq.empty`)
- If a single value is passed in, ...
    - ... and it's a _sequence_, it's returned without any further processing
    - ... and it's a `table` with a non-`nil` value at index 1, it's iterated using `ipairs` (see `linq.array`)
    - ... and it's a `table` that __doesn't__ have a non-`nil` value at index 1, the table is iterated using `pairs` (see `linq.table`)
    - ... and it's a `function`, it's called repeatedly to generate the values of the sequence (see `linq.iterator`)
    - ... and none of the above checks match, a sequence containing the parameter is returned (see `linq.params`)
- If more than one parameter is passed in, a sequence containing all parameters, in order, is returned (see `linq.params`)

## `linq.array(table)`
## `linq.empty()`
## `linq.factory(factory)`
## `linq.iterator(func)`
## `linq.range(start, count)`
## `linq.rep(value, count)`
## `linq.table(table)`
## `linq.params(...)`

# Intermediate Functions

## `linq:where(predicate)`

Returns a sequence that only contains the elements from the source that satisfy the predicate. This function is sometimes also called `filter` (e.g. in Java Streams, JavaScript) and can also be used as such.

```lua
local seq = linq {
    { name = "Jane Doe", role = "Manager" },
    { name = "Jonathan Doe", role = "Trainee" },
    { name = "John Doe", role = "Manager" }
}:where(function(person) return person.role == "Manager" end)
--[[ seq is now linq {
    { name = "Jane Doe", role = "Manager" },
    { name = "John Doe", role = "Manager" }
}
]]
```

## `linq:select(selector)`

Projects every element of the source sequence to a new element. This function is sometimes also called `map` (e.g. in Java Streams, JavaScript) and can also be used as such.

```lua
local seq = linq { "cat", "bird", "penguin" }
    :select(function(s) return #s end)
-- seq is now linq { 3, 4, 7 }
```

## `linq:selectMany(collectionSelector, [resultSelector])`

`selectMany` projects each element of the source sequence to an 'inner' sequence and then flattens the results into a single sequence. This function is also called `flatMap` (e.g. in Java Streams, JavaScript) and can also be used as such. The selector does not need to return linq sequences, as `linq.new` will be called on the returned values.

A second parameter, the `resultSelector`, can be used to transform the inner elements even further. It will be called with four parameters: the _outer_ value and index, followed by the _inner_ value and index. 

```lua
-- Simplest case: flatten a sequence of nested tables
local seq = linq { 
    { "a", "b" }, 
    { "c" } 
}:selectMany(function(t) return t end)
--[[ seq is now linq { 
    "a", 
    "b", 
    "c" 
}
]]

-- Using the result selector to allow for more complex result items
local booksAndAuthors = linq { 
    { 
        author = "Brandon Sanderson",
        name = "Mistborn",
        books = {
            "The Final Empire",
            "The Well of Ascension",
            "The Hero of Ages"
        }
    },
    {
        author = "Patrick Rothfuss",
        name = "The Kingkiller Chronicle",
        books = {
            "The Name of the Wind",
            "The Wise Man's Fear"
        }
    }
}:selectMany(
    function(t, _) return t.books end,
    function(series, _, book, bookIndex) 
        return ("%s (Book %d of %s) by %s"):format(book, bookIndex, series.name, series.author) 
    end
)
--[[ booksAndAuthors is now linq {
    "The Final Empire (Book 1 of Mistborn) by Brandon Sanderson",
    "The Well of Ascension (Book 2 of Mistborn) by Brandon Sanderson",
    "The Hero of Ages (Book 3 of Mistborn) by Brandon Sanderson",
    "The Name of the Wind (Book 1 of The Kingkiller Chronicle) by Patrick Rothfuss",
    "The Wise Man's Fear (Book 2 of The Kingkiller Chronicle) by Patrick Rothfuss"
}
]]
```

## `linq:batch(size)`

Creates a sequence of tables containing the specified number values (and indices) each, with a trailing batch containing any 'left over' values. Note that, other than [`linq:batchValues`](#linqbatchvaluessize), this will create batches of _nested_ tables, each containing both the value and the index taken from the source sequence.

```lua
local seq = linq { "a", "b", "c" }:batch(2)
--[[ seq is now equivalent to linq { 
    { 
        { "a", 1 }, 
        { "b", 2 },
    },
    { 
        { "c", 3 },
    }
}
]]
```

## `linq:batchValues(size)`

Creates a sequence of tables containing the specified number of values each, with a trailing batch containing any 'left over' values. Note that, other than [`linq:batch`](#linqbatchsize), this creates _flat_ tables containing _only_ the values of the source sequence, the indices are _lost_.

```lua
local seq = linq { "a", "b", "c" }:batchValues(2)
--[[ seq is now equivalent to linq {
    { "a", "b" },
    { "c" }
}
]]
```

## `linq:windowed(size)`

Creates a sequence of tables containing a 'sliding window' view of the specified size over the source sequence. The resulting values are tables of _exactly_ the size specified. If the source sequence contains fewer values than required to create a single window, no windows will be generated, resulting in an empty result sequence.

Note that the indices are _lost_ in this operation.

```lua
local seq = linq { "a", "b", "c", "d", "e" }:windowed(3)
--[[ seq is now equivalent to linq {
    { "a", "b", "c" },
    { "b", "c", "d" },
    { "c", "d", "e" }
}
]]
```

## `linq:orderBy(selector, [comparer])`
## `linq:orderByDescending(selector, [comparer])`
## `linq:thenBy(selector, [comparer])`
## `linq:thenByDescending(selector, [comparer])`
## `linq:unique()`
## `linq:uniqueBy(selector)`
## `linq:skip(count)`

This operator skips the specified number of items in a sequence, yielding only the remaining values:

```lua
local seq = linq { "a", "b", "c", "d" }:skip(2)
-- seq is now equivalent to linq { "c", "d" }
```

## `linq:take(count)`

This operator yields the first `count` items from the source sequence, stopping after the specified amount.

```lua
local seq = linq { "a", "b", "c" }:take(2)
-- seq is now equivalent to linq { "a", "b" }
```

## `linq:zip(other, resultSelector)`
## `linq:defaultIfEmpty(defaultValue, defaultIndex)`
## `linq:reindex()`
## `linq:nonNil()`
## `linq:concat(other)`

# Terminal Functions

## `linq:aggregate(seed, selector)`
## `linq:count([predicate])`
## `linq:sum([selector])`
## `linq:max([selector])`
## `linq:min([selector])`
## `linq:any([predicate])`
## `linq:all(predicate)`
## `linq:first([predicate])`
## `linq:firstOr([predicate], defaultValue, defaultIndex)`
## `linq:single([predicate])`
## `linq:singleOr([predicate], defaultValue, defaultIndex)`
## `linq:last([predicate])`
## `linq:lastOr([predicate], defaultValue, defaultIndex)`
## `linq:sequenceEquals(other, [comparer])`
## `linq:toArray()`
## `linq:toTable()`
## `linq:getIterator()`
## `linq:foreach(func)`

# Metafunctions

## `__len` (`#sequence`)

Yields the number of elements in a sequence, similar to [`linq:count`](#linqcountpredicate). This allows accessing the number of elements using the `#` operator:

> Please note that using `#sequence` still iterates (and possibly consumes) the whole sequence, it's really *just* a shortcut to `sequence:count()`!

```lua
local sequence = linq { 1, 2, 3, 4, 5, 6 }
    :where(function(x) return x % 2 == 1 end)

local length = #sequence -- length is 3
```

## `__concat` (`seqA .. seqB`)

Concatenates two (or more!) sequences using the concatenation operator `..`. This does the same as calling [`linq:concat`](#linqconcatother).

```lua
local sequence = linq { "Hello" } .. linq { "World" }
-- sequence is now equivalent to linq { "Hello", "World" }
```

## `__pairs` (`for key, value in pairs(seq) do`)

Allows iterating a sequence in a `for` loop using Lua's `pairs` method (or, alternatively, using `:pairs`):

```lua
-- Using Lua's pairs(...):
for _, value in pairs(linq(1, 2, 3, 4, 5, 6):where(function(i) return i % 2 == 1 end)) do
    print(value)
end

-- Or, using the :pairs() alias:
for _, value in linq(1, 2, 3, 4, 5, 6):where(function(i) return i % 2 == 1 end):pairs() do
    print(value)
end

-- Both variants print:
-- 1
-- 3
-- 5
```

## String Lambdas

LazyLuaLinq supports string lambdas as a short-hand form of anonymous functions. Whenever a function accepts a function (e.g. a predicate or a transformation), you may also pass a string instead. For example, the following two snippets are functionally identical:

```lua
local sequence = linq.range(1, 10)

sequence:where(function(x) return x % 2 == 0 end):foreach(print)

-- The same filter with a string lambda
sequence:where("v % 2 == 0"):foreach(print)
```

> It's important to note that string lambdas load and execute code at runtime (via Lua's [`load` function](https://www.lua.org/manual/5.4/manual.html#pdf-load)). This requires that `load` is available at runtime. 
> 
> Please also note that this means you shouldn't include unsanitized user input in your string lambdas, as it may allow [code injection](https://en.wikipedia.org/wiki/Code_injection). If you need to use user input in a function, you should always prefer to use anonymous functions over string lambdas.

There are two ways to specify a string lambda. The first form, which can be seen above, only specifies the return value(s). The function parameters can be accessed with the variables k (the key of the sequence) and v (the corresponding value). If you want to specify names for the parameters for clarity, you may use the lambda syntax: `(v, k) => (v % 2 == 0)`.

Note that: 

1. Parameters are always passed in the order `value`, `key` (except for the `foreach` operator).
2. You may specify any number of parameters for a lambda function. However, only two parameters will ever be passed (except for selectMany). As is common for Lua, you may specify fewer parameters than are actually passed.
3. If you do not need to specify parameter names, you can omit the first part of the string lambda as seen above. If no parameter names are specified explicitely, `v` and `k` are used (in that order).
4. You may omit the parentheses that enclose the parameters as well as the return values. Thus, `v => v * 2` is as valid as `(v) => (v * 2)`.
5. As is common in Lua, you may return any number of values from a lambda, though most operators will only use the first two return values.

If you should want to use lambdas for other uses than in LazyLuaLinq, you can use the `lambda` function:

```lua
local timesTwo = linq.lambda("v => v * 2")
-- local function timesTwo(v) return v * 2 end
```

# Module Configuration

There are various functions that can be called directly on the `linq` module in order to configure the way it works.
As of today, all available configuration functions are used to increase the safety of [String Lambdas](string-lambdas).

> Please note that these functions _globally_ alter the behavior of LazyLuaLinq. Due to the fact that Lua's `require`
> function caches the module after loading it for the first time, there's only a single instance of `linq`, even
> when `require`-ing it multiple times. Thus, you cannot (currently) have multiple `linq` instances with different
> behaviors.

## `disableLambdas`

Fully disables lambdas globally. Please note that this also disables the use of `linq.lambda` from your own code, though
this may change in the future.

```lua
local linq = require("lazylualinq").disableLambdas()

linq { 1, 2, 3 }:select("v => v * 2") -- error: Lambdas have been disabled
```

## `withLambdaEnv`

Sets an environment to use whenever a lambda is created. Note that this environment will also be used when calling 
`linq.lambda` from your own code, though this may change in the future.

This function can be used to execute string lambdas in a sandbox, preventing access to potentially dangerous functions
such as filesystem access or `load`/`loadstring`.

```lua
local linq = require("lazylualinq").withLambdaEnv({})
local func = linq.lambda("_ => os")

print(func()) -- nil
```

## `withLoadString`

Sets a custom function to load a chunk from a string. The function will be called with two arguments: `chunk` and `env`.
The provided function may perform any operation on the chunk before actually loading it. The passed `env` represents
the environment that the chunk should be executed in (as set per [`withLambdaEnv`](#withLambdaEnv)).

This function may be used to make string lambdas work in more restricted environments. *You should only use this
function in environments where string lambdas do not work by default.* 

For example, LazyLuaLinq uses the equivalent of the following code to make string lambdas work in Lua 5.1:

```lua
local linq = require("lazylualinq")
    .withLoadString(function(chunk, env)
        local func = loadstring(chunk)
        if func == nil then
            return nil
        end

        setfenv(func, env)
        return func
    end)
```