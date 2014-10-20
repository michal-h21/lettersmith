local microtest = require("microtest")
local suite = microtest.suite
local test = microtest.test
local equal = microtest.equal

local list = require("colist")
local map = list.map
local values = list.values
local merge = list.merge
local concat = list.concat
local collect = list.collect
local filter = list.filter
local zip_with = list.zip_with

suite("map()", function ()
  function mult2(x) return x * 2 end

  local v = values({1, 2, 3})
  local x = map(v, mult2)
  local t = collect(x)

  test(t[1] == 2 and t[2] == 4 and t[3] == 6, "All items mapped")
end)

suite("filter()", function ()
  local a = values({'a', 'b', 'a'})
  local b = filter(a, function (x) return x == 'a' end)
  local t = collect(b)

  test(table.getn(t) == 2, "Correct number of items passed")
  test(t[1] == 'a' and t[2] == 'a', "Only contains items passing test")
end)

suite("merge()", function ()
  local a = values({1, 2, 3})
  local b = values({4, 5, 6})
  local ab = merge(a, b)
  local t = collect(ab)

  test(table.getn(t) == 6, "All items collected")
end)

suite("concat()", function ()
  local a = values({1, 2, 3})
  local b = values({4, 5, 6})
  local ab = concat(a, b)
  local t = collect(ab)

  test(table.getn(t) == 6, "All items collected")

  equal(t[1], 1, "Items in a collected before table b")
  equal(t[5], 5, "Items in b collected after table a")
end)

suite("zip_with()", function ()
  function sum(a, b) return a + b end
  local a = values({1, 2, 3})
  local b = values({4, 5, 6})
  local ab = zip_with(a, b, sum)
  local t = collect(ab)

  test(table.getn(t) == 3, "All items collected")
  test(t[1] == 5 and t[2] == 7 and t[3] == 9, 'Items zipped correctly')
end)
