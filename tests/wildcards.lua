local microtest = require("microtest")
local suite = microtest.suite
local equal = microtest.equal
local test = microtest.test

local wildcards = require("wildcards")

suite("wildcards.parse(wildcard_path_string)", function()
  local pattern = wildcards.parse("foo/*.md")

  test(string.find("foo/bar.md", pattern), "* matched path correctly")

  test(not string.find("baz/foo/bar.md", pattern), "* matched from beginning")

  local pattern_b = wildcards.parse("foo/**.md")

  test(string.find("foo/bar/baz/bing.md", pattern_b), "** matched path correctly")

  test(not string.find("baz/foo/bar.md", pattern_b), "** matched from beginning")

  local pattern_c = wildcards.parse("foo/?.md")

  test(string.find("foo/b.md", pattern_c), "? matched path correctly")

  test(not string.find("foo/bar.md", pattern_c), "? did not match more than one char")
end)