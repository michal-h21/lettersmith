local microtest = require('microtest')
local suite = microtest.suite
local test = microtest.test

local path = require('path')
local resolve_up_dir_traverse = path.resolve_up_dir_traverse
local remove_trailing_slash = path.remove_trailing_slash

suite('path.remove_trailing_slash()', function ()
  test(remove_trailing_slash('..') == '..', "Leaves text without a trailing slash alone")

  local x = remove_trailing_slash('../') == '..' and remove_trailing_slash('bar/../') == 'bar/..'
  test(x, "Removes trailing slash")

  test(remove_trailing_slash('/') == '/', "Leaves strings alone when they only contain a slash")
end)

suite("path.unshift(s)", function ()
  test(path.unshift("..") == '..', "Handles .. correctly")

  local x, y = path.unshift("foo/bar/baz")
  local z = x == "foo" and y == "bar/baz"
  test(z, "Handles foo/bar/baz")

  -- @fixme handle this case better
  -- test(path.unshift("./"))
end)

suite('path.normalize(s)', function ()
  test(path.normalize('./foo/././') == 'foo', "Resolved same dir")
  test(path.normalize('./foo/././bar') == 'foo/bar', "Resolved same dir followed by dir")
  test(path.normalize('./foo/./.') == 'foo', "Resolved same dir with trailing dot")

  test(path.normalize("..") == '..', "Handled .. correctly")
  test(path.normalize("../") == "..", "Resolved ../ correctly")
  test(path.normalize('bar/../foo') == "foo", "Resolved bar/../foo to foo")
  test(path.normalize('bar/../') == ".", "Resolved bar/../ to .")
  test(path.normalize("/../../") == "/", "Resolved /../../ to /")
end)

suite("path.join()", function ()
  test(path.join("..", "foo") == "../foo", ".., foo joined to ../foo")
end)