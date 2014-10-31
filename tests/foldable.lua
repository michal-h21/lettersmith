local microtest = require("microtest")
local suite = microtest.suite
local equal = microtest.equal
local test = microtest.test

local _ = require("foldable")
local fold = _.fold
local map = _.map
local filter = _.filter
local reject = _.reject
local collect = _.collect
local concat = _.concat
local take = _.take

local function sum(x, y)
  return x + y
end

local function inc(x)
  return x + 1
end

local function is_even(x)
  return x % 2 == 0
end

suite("fold(foldable, step, seed)", function()
  local t = {1, 2, 3}

  local tally_a = fold(t, sum, 0)
  equal(tally_a, 6, "It can fold a table")

  local tally_b = fold(1, sum, 0)
  equal(tally_b, 1, "It can fold a value")

  local tally_c = fold(nil, sum, 0)
  equal(tally_c, 0, "It can fold a nil")

  function foldable_example(step, seed)
    local i = 0
    while i < 3 do
      i = i + 1
      seed = step(seed, i)
    end
    return seed
  end

  local tally_d = fold(foldable_example, sum, 0)
  equal(tally_d, 6, "It can fold a foldable function")
end)

suite("collect(foldable)", function()
  local a = {1, 2, 3}

  local collected_a = collect(a)

  test(collected_a ~= a, "Returns a new table")
  equal(collected_a[1], 1, "Collects ipairs in order")
end)

suite("map(foldable, transform)", function()
  local t = {1, 2, 3}

  local mapped = map(t, inc)

  local mapped_t = collect(mapped)

  equal(mapped_t[1], 2, "Maps values using transform function")
end)

suite("filter(foldable, predicate)", function()
  local t = {1, 2, 3}

  local a = filter(t, is_even)

  local b = collect(a)

  equal(#b, 1, "Filters out correct number of values")
  equal(b[1], 2, "Includes values that match predicate")
end)

suite("reject(foldable, predicate)", function()
  local t = {1, 2, 3}

  local a = reject(t, is_even)

  local b = collect(a)

  equal(#b, 2, "Rejects correct number of values")
  equal(b[1], 1, "Includes values that match predicate")
end)

suite("concat(foldable_a, foldable_b)", function()
  local t = {1, 2, 3}

  local tt = concat(t, t)

  local b = collect(tt)

  equal(#b, 6, "Concat folds correct number of values")
  equal(b[4], 1, "Folds foldable_b after foldable_a")
end)

suite("take()", function ()
  local a = {1, 2, 3, 4, 5, 6}

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
