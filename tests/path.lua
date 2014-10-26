local microtest = require('microtest')
local suite = microtest.suite
local test = microtest.test
local equal = microtest.equal

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
  equal(x, "foo", "Handles foo/bar/baz head")
  equal(y, "bar/baz", "Handles foo/bar/baz tail")

  local x, y = path.shift("/foo/bar")
  local z = x == "/" and y == "foo/bar"
  equal(x, "/", "Handles /foo/bar head, returning /")
  equal(y, "foo/bar", "Handles /foo/bar tail, returning foo/bar")

  equal(path.shift("bar/"), "bar", "Handles bar/ correctly, returning bar")

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

suite("path.parts(location_string)", function ()
  local a = path.parts("foo/bar/baz")
  equal(a[1], "foo", "Handled part 1")
  equal(a[2], "bar", "Handled part 2")
  equal(a[3], "baz", "Handled part 3")
end)

suite("path.basename(location_string)", function ()
  equal(path.basename("foo/bar/baz"), "baz", "Basename is baz")
  equal(path.basename("foo/bar/baz.html"), "baz.html", "Basename is baz.html")

  local basename, rest = path.basename('foo/bar/baz.html')
  equal(rest, "foo/bar", "The rest of path is foo/bar")
end)

suite("path.extension(path_string)", function ()
  equal(path.extension("foo/bar/baz"), "", "Returns empty string for no extension")
  equal(path.extension("foo/bar.md"), ".md", "Returns extension")
end)

suite("path.replace_extension(path_string, new_extension)", function ()
  local x = path.replace_extension("foo/bar/baz.md", ".html")
  equal(x, "foo/bar/baz.html", "Replaces extension")

  local y = path.replace_extension("bing/baz.foo.bar.md", ".html")
  equal(y, "bing/baz.foo.bar.html", "Replaces only last extension")
end)