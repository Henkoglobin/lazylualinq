# lazylualinq

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
- [Supported Operators](#supported-operators)
    - [Constructors](#constructors)
    - [Intermediate Functions](#intermediate-functions)
    - [Terminal Functions](#terminal-functions)
    - [Metafunctions](#metafunctions)
    - [String Lambdas](#string-lambdas)

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

# Supported Operators

There are three major categories of functions (or operators) in lazylualinq: Constructors (functions that create a sequence of values from some kind of source), intermediate functions (that perform some kind of transformative operation on a sequence, such as filtering or projections) and terminal functions (which also perform a transformative operation on a sequence, but return a value that's _not_ a sequence). 

## Constructors

Constructors are methods that produce a sequence of values on which other operations can then be performed. 

### `linq.new`

`linq.new(...)`, also available simply as `linq(...)` or `linq.from(...)`. This constructor _guesses_ the caller's intentions based on the number and types of parameters passed. 

- If no parameters are passed, this returns an empty sequence (see `linq.empty`)
- If a single value is passed in, ...
    - ... and it's a _sequence_, it's returned without any further processing
    - ... and it's a `table` with a non-`nil` value at index 1, it's iterated using `ipairs` (see `linq.array`)
    - ... and it's a `table` that __doesn't__ have a non-`nil` value at index 1, the table is iterated using `pairs` (see `linq.table`)
    - ... and it's a `function`, it's called repeatedly to generate the values of the sequence (see `linq.iterator`)
    - ... and none of the above checks match, a sequence containing the parameter is returned (see `linq.params`)
- If more than one parameter is passed in, a sequence containing all parameters, in order, is returned (see `linq.params`)

### `linq.array`
### `linq.empty`
### `linq.factory`
### `linq.iterator`
### `linq.range`
### `linq.rep`
### `linq.table`
### `linq.params`

## Intermediate Functions

### `linq:where`
### `linq:select`
### `linq:selectMany`
### `linq:orderBy`
### `linq:orderByDescending`
### `linq:thenBy`
### `linq:thenByDescending`
### `linq:unique`
### `linq:uniqueBy`
### `linq:zip`
### `linq:defaultIfEmpty`
### `linq:reindex`
### `linq:nonNil`
### `linq:concat`

## Terminal Functions

### `linq:aggregate`
### `linq:count`
### `linq:sum`
### `linq:max`
### `linq:min`
### `linq:any`
### `linq:all`
### `linq:first`
### `linq:firstOr`
### `linq:single`
### `linq:singleOr`
### `linq:last`
### `linq:lastOr`
### `linq:sequenceEquals`
### `linq:toArray`
### `linq:toTable`
### `linq:getIterator`
### `linq:foreach`

## Metafunctions

### `__index` (`sequence[index]`)
### `__len` (`#sequence`)
### `__concat` (`seqA .. seqB`)

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
