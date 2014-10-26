local microtest = require("microtest")
local suite = microtest.suite
local equal = microtest.equal
local test = microtest.test

local query = require("query")

suite("query.parse(path_query_string)", function()
  local pattern = query.parse("foo/*.md")

  test(string.find("foo/bar.md", pattern), "* matched path correctly")

  local pattern_b = query.parse("foo/**.md")

  test(string.find("foo/bar/baz/bing.md", pattern_b), "** matched path correctly")
end)