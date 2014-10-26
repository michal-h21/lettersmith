local microtest = require("microtest")
local suite = microtest.suite
local equal = microtest.equal
local test = microtest.test

local query = require("query")

suite("query.parse(path_query_string)", function()
  local pattern = query.parse("foo/*.md")

  test(string.find("foo/bar.md", pattern), "* matched path correctly")

  test(not string.find("baz/foo/bar.md", pattern), "* matched from beginning")

  local pattern_b = query.parse("foo/**.md")

  test(string.find("foo/bar/baz/bing.md", pattern_b), "** matched path correctly")

  test(not string.find("baz/foo/bar.md", pattern_b), "** matched from beginning")

  local pattern_c = query.parse("foo/?.md")

  test(string.find("foo/b.md", pattern_c), "? matched path correctly")

  test(not string.find("foo/bar.md", pattern_c), "? did not match more than one char")
end)