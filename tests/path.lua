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

suite("path.shift(s)", function ()
  test(path.shift("..") == '..', "Handles .. correctly")

  local x, y = path.shift("foo/bar/baz")
  local z = x == "foo" and y == "bar/baz"
  test(z, "Handles foo/bar/baz")

  local x, y = path.shift("/foo/bar")
  local z = x == "/" and y == "foo/bar"
  test(z, "Handles /foo/bar")

  test(path.shift("bar/") == "bar", "Handles bar/ correctly")

  -- @fixme handle this case better
  -- test(path.shift("./"))
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

suite("path.parts(s)", function ()
  local parts = path.parts('/foo/bar/baz')
  local a = parts() == '/'
  local b = parts() == 'foo'
  local c = parts() == 'bar'
  test(a and b and c, "Handles /foo/bar/baz")
end)