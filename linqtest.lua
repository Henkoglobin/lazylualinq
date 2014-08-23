local linq = require("linq")

-- Test array constructor
print("Testing array constructor...")
local arr = linq { 1, 2, 3, 4 }
arr:foreach(print)

-- Test table constructor
print("Testing table constructor...")
local tab = linq { a = 1, b = 2, c = 3 }
tab:foreach(print)

-- Test parameter constructor
print("Testing parameter constructor...")
local par = linq ( 1, 2, 3, 4 )
par:foreach(print)

-- Test empty constructor
print("Testing empty constructor...")
local emp1 = linq.empty()
local emp2 = linq.empty()

emp1:foreach(print)
print("emp1 and emp2 are identical: " .. tostring(emp1 == emp2))

-- Test iterator constructor
print("Testing iterator constructor...")
local it = linq(string.gmatch("banana", "na"))
it:foreach(print)
it:foreach(print)

-- Test range constructor
print("Testing range constructor...")
local ran = linq.range(10, 10)
ran:foreach(print)

-- Test rep constructor
print("Testing rep constructor...")
local rep = linq.rep("Hello", 5)
rep:foreach(print)

-- Test where operator with anonymous function
print("Testing where operator with anonymous function...")
local seq = linq.range(1, 10)
seq:where(function(x) return x % 2 == 1 end):foreach(print)

-- Test where operator with string lambda
print("Testing where operator with string lambda...")
seq:where("v % 2 == 0"):foreach(print)

-- Test select operator with anonymous function
print("Testing select operator with anonymous function...")
seq:select(function(x) return x + 10 end):foreach(print)

-- Test select operator with string lambda
print("Testing select operator with string lambda...")
seq:select("v - 10"):foreach(print)