local microtest = require("microtest")
local suite = microtest.suite
local test = microtest.test
local equal = microtest.equal

local list = require("streams")
local map = list.map
local values = list.values
local merge = list.merge
local concat = list.concat
local collect = list.collect
local filter = list.filter
local zip_with = list.zip_with
local take = list.take
local skim = list.skim
local prepend = list.prepend
local chunk = list.chunk

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

  test(#t == 2, "Correct number of items passed")
  test(t[1] == 'a' and t[2] == 'a', "Only contains items passing test")
end)

suite("merge()", function ()
  local a = values({1, 2, 3})
  local b = values({4, 5, 6})
  local ab = merge(a, b)
  local t = collect(ab)

  test(#t == 6, "All items collected")
end)

suite("concat()", function ()
  local a = values({1, 2, 3})
  local b = values({4, 5, 6})
  local ab = concat(a, b)
  local t = collect(ab)

  test(#t == 6, "All items collected")

  equal(t[1], 1, "Items in a collected before table b")
  equal(t[5], 5, "Items in b collected after table a")
end)

suite("zip_with()", function ()
  function sum(a, b) return a + b end
  local a = values({1, 2, 3})
  local b = values({4, 5, 6})
  local ab = zip_with(a, b, sum)
  local t = collect(ab)

  test(#t == 3, "All items collected")
  test(t[1] == 5 and t[2] == 7 and t[3] == 9, 'Items zipped correctly')
end)

suite("take()", function ()
  local a = values({1, 2, 3, 4, 5, 6})

  local a_3 = take(a, 3)

  local t = collect(a_3)

  equal(t[3], 3, "Took up to correct number")
  equal(t[4], nil, "Did not take beyond correct number")

  local a_3_3 = take(a, 3.3)
  local a_3_3 = collect(a_3_3)

  equal(t[3], 3, "Handles taking floats by rounding down to nearest int")

  local huge_stream = take(a, math.huge)

  -- Note this is not a formal API requirement, just an optimization.
  equal(huge_stream, a, "Returns original stream when number of items is math.huge")
end)

suite("prepend()", function ()
  local a = values({2, 3, 4, 5, 6})

  local b = prepend(a, 1)

  local t = collect(b)

  equal(t[1], 1, "Prependeds value")
  equal(t[2], 2, "...Then consumes stream")
end)

suite("skim()", function ()
  function is_greater_than(a, b)
    return a > b
  end

  local a = values({1, 2, 3, 4, 5, 6})

  local top_3 = skim(a, is_greater_than, 3)

  equal(top_3[3], 4, "Sorted correctly")
  equal(top_3[1], 6, "Sorted correctly")
  equal(#top_3, 3, "Did not take beyond correct number")
end)

suite("chunk(stream, n)", function ()
  local a = values({1, 2, 3, 4, 5, 6, 7})

  local pairs_stream = chunk(a, 3)

  local pairs_list = collect(pairs_stream)

  equal(pairs_list[1][1], 1, "Chunks stream")
  equal(pairs_list[1][2], 2, "Chunks stream")
  equal(#pairs_list, 3, "Chunks correct number of chunks")
  equal(#pairs_list[3], 1, "Collects leftover chunk")
end)