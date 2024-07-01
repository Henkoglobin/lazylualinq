package = "lazylualinq"
rockspec_format = "3.0"
version = "scm-1"
source = {
   url = "git://github.com/Henkoglobin/lazylualinq",
   tag = "main"
}
description = {
   summary = "LazyLuaLinq provides a simple, lazy implementation of linq-like functions for Lua.",
   detailed = [[
      LazyLuaLinq provides a simple, lazy implementation of linq-like functions for Lua. 
      With LazyLuaLinq, you can implement data transformation in elegant, 
      expressive queries akin to SQL.
   ]],
   homepage = "https://henkoglobin.github.io/lazylualinq",
   license = "Unlicense"
}
dependencies = {
   "lua >= 5.1, < 5.5"
}
test_dependencies = {
   "busted >= 2.2.0-1",
   "luacov >= 0.15.0-1",
   "luacov-html >= 1.0.0-1"
}
build = {
   type = "builtin",
   modules = {
      ["lazylualinq"] = "src/lazylualinq.lua",
      ["lazylualinq.ordering"] = "src/lazylualinq/ordering.lua",
   }
}
