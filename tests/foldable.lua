local microtest = require("microtest")
local suite = microtest.suite
local equal = microtest.equal
local test = microtest.test

local _ = require("lettersmith.foldable")
local fold = _.fold
local map = _.map
local filter = _.filter
local reject = _.reject
local collect = _.collect
local concat = _.concat
local take = _.take
local zip_with = _.zip_with
local chunk = _.chunk
local harvest = _.harvest
local folds = _.folds

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

suite("folds()", function ()
  local a = {1, 2, 3}

  local permutations = folds(a, sum, 0)

  local b = collect(permutations)

  equal(b[1], 1, "Generates first permutation correctly")
  equal(b[2], 3, "Generates second permutation correctly")
  equal(b[3], 6, "Generates third permutation correctly")
  equal(#b, 3, "Generates correct number of permutations")
end)

suite("concat(foldable_a, foldable_b)", function()
  local t = {1, 2, 3}

  local tt = concat(t, t)

  local b = collect(tt)

  equal(#b, 6, "Concat folds correct number of values")
  equal(b[4], 1, "Folds foldable_b after foldable_a")
end)

suite("zip_with()", function ()
  local a = {1, 2, 3}
  local b = {4, 5, 6}
  local ab = zip_with(a, b, sum)
  local t = collect(ab)

  test(#t == 3, "All items collected")
  test(t[1] == 5 and t[2] == 7 and t[3] == 9, 'Items zipped correctly')
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

suite("chunk(foldable, n)", function ()
  local a = {1, 2, 3, 4, 5, 6, 7}

  local chunks = chunk(a, 3)

  local b = collect(chunks)

  equal(b[1][1], 1, "Chunks it!")
  equal(b[1][2], 2, "Chunks it!")
  equal(#b, 3, "Chunks correct number of chunks")
  equal(#b[3], 1, "Collects leftover chunk")

  local even_chunks = chunk({1, 2}, 2)

  local c = collect(even_chunks)

  equal(c[1][1], 1, "Chunks even chunks!")
  equal(c[1][2], 2, "Chunks even chunks!")
  equal(#c, 1, "Chunks correct number of chunks")
  equal(#c[1], 2, "Collects leftover chunk")
end)

suite("harvest()", function ()
  function is_greater_than(a, b)
    return a > b
  end

  local a = {1, 2, 3, 4, 5, 6}

  local top_3 = harvest(a, is_greater_than, 3)

  equal(top_3[3], 4, "Sorted correctly")
  equal(top_3[1], 6, "Sorted correctly")
  equal(#top_3, 3, "Did not take beyond correct number")
end)
