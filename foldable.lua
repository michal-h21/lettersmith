-- A reinterpretation of Clojure Reducers for Lua.

local exports = {}

-- Fold a table into a result from a `seed` using `step` function.
-- Call `step` with value and index, updating `seed` with return value.
local function fold_table(t, step, seed)
  for i, v in ipairs(t) do seed = step(seed, v) end
  return seed
end

-- Define a generic fold function for almost any type of value. You can fold:
-- foldable functions (the kind returned from `map`, `filter`, etc),
-- tables, single values, even `nil`. The only thing you can't fold are
-- functions that are not foldable functions.
--
-- `fold` takes a `step` function, a `seed` value and returns the folded
-- result of our calculation.
local function fold(foldable, step, seed)
  if type(foldable) == "function" then
    -- Foldable functions are functions can take a `step` function and a `seed`
    -- value and fold themselves, returning a value.
    return foldable(step, seed)
  elseif type(foldable) == "table" then
    -- Tables are folded using ipairs.
    return fold_table(foldable, step, seed)
  elseif foldable ~= nil then
    -- Other non-nil values are treated as a single step over themselves.
    return step(foldable, seed)
  else
    -- Nil values get no step at all.
    return seed
  end
end
exports.fold = fold

-- The colleciton functions, `map`, `filter`, etc below are all described in
-- terms of our generic `fold` above. This means that these functions may be
-- used on any value type.
--
-- All collection functions return a foldable function. What does this mean?
-- Unlike traditional `map`, `filter`, etc, foldable functions don't create
-- intermediate tables. Instead, a foldable function creates a recipe for
-- folding the source so it would result in the same value. When you pass a
-- foldable function to `fold`, it kicks off the actual work, and a folded
-- value is returned.
--
-- This makes it extremely efficient to chain multiple `map`, `filter`, etc over
-- long (even potentially infinite) data sources.
--
-- See http://clojure.com/blog/2012/05/15/anatomy-of-reducer.html for more on
-- this idea.

-- A higher-level function that will create a folding transformation
-- with a collection-like API from a `transforming` recipe that will 
-- transform the `step` function.
local function transformer(transforming)
  return function (foldable, additional)
    return function (step, seed)
      return fold(foldable, transforming(step, additional), seed)
    end
  end
end
exports.transformer = transformer

-- Define map in terms of a fold `step` transformation.
local map = transformer(function (step, transform)
  return function(seed, v)
    return step(seed, transform(v))
  end
end)
exports.map = map

-- Define `filter` in terms of a fold `step` transformation.
local filter = transformer(function (step, predicate)
  return function(seed, v)
    if predicate(v) then
      return step(seed, v)
    else
      return seed
    end
  end
end)
exports.filter = filter

local reject = transformer(function (step, predicate)
  return function(seed, v)
    if not predicate(v) then
      return step(seed, v)
    else
      return seed
    end
  end
end)
exports.reject = reject

-- @todo I'm pretty sure I can better express my weird map/filter situations
-- with a `folds` function. The idea is that a passing value returns transformed
-- seed, whereas a non-passing value simply returns seed.

-- Wrap `table.insert` with a fold-friendly interface.
local function append_to_table(t, v)
  -- Append a value to a table, mutating table.
  -- Returns mutated table.
  table.insert(t, v)
  return t
end

-- Collect all items of foldable into a Lua table. Useful if you want to index
-- the values in a foldable function, for example. If foldable is already a
-- table, this will give you a new shallow-copied table.
-- Returns a table.
local function collect(foldable)
  return fold(foldable, append_to_table, {})
end
exports.collect = collect

local function yield_next_ipair(i, v)
  i = i + 1
  coroutine.yield(i, v)
  return i
end

-- Convert any foldable to a for loop-compatible coroutine. The coroutine will
-- return an index and a value for each turn of the loop.
-- Returns a coroutine function.
local function foldable_ipairs(foldable)
  return coroutine.wrap(function ()
    fold(foldable, yield_next_ipair, 0)
  end)
end
exports.ipairs = foldable_ipairs

-- Concatenate two foldable things together.
-- `foldable_a` will be reduced in full before `foldable_b`.
-- Returns a new foldable function good for the result of the folds.
local function concat(foldable_a, foldable_b)
  return function(step, seed)
    seed = fold(foldable_a, step, seed)
    seed = fold(foldable_b, step, seed)
    return seed
  end
end
exports.concat = concat

-- Take up to `n` number of items from foldable.
-- Returns a new foldable containing at most `n` items.
local function take(foldable, n)
  -- If taking less than one item, return nil (which is foldable for 0 steps).
  if n < 1 then return nil end

  -- Just return original foldable if number of items to take is infinite.
  if n == math.huge then return foldable end

  return function(step, seed)
    fold(foldable, function (taken, v)
      -- If we've not taken up to the requested amount yet, step with value.
      -- Return the number of taken items.
      if taken < n then
        seed = step(seed, v) return taken + 1

      -- Ignore further input if we're past the requested amount.
      else
        return n
      end
    end, 0)
    return seed
  end
end
exports.take = take

-- Divide a foldable into chunks, returning a new foldable function good for
-- tables containing `n` items.
local function chunk(foldable, n)
  return function (step, seed)
    local last_chunk = fold(foldable, function (chunk, v)
      -- If chunk has reached size, then send chunk to `step` and start a new
      -- chunk.
      if (#chunk == n) then
        seed = step(seed, chunk)
        return append_to_table({}, v)

      -- Otherwise, append value to chunk table.
      else
        return append_to_table(chunk, v)
      end
    end, {})

    -- Finally, return the last folded value from the last chunk.
    return step(seed, last_chunk)
  end
end
exports.chunk = chunk

local function chop(t, n)
  -- Remove items from end of table `t`, until table length is `n`.
  -- Mutates and returns table.
  while #t > n do table.remove(t, #t) end
  return t
end

local function chop_sorted_buffer(buffer_table, compare, n)
  -- Sort `buffer_table` and remove elements from end until buffer is only
  -- `n` items long.
  -- Mutates and returns buffer.
  table.sort(buffer_table, compare)
  return chop(buffer_table, n)
end

local function harvest(foldable, compare, n)
  -- Skim the cream off the top... given a foldable, a comparison function
  -- and a buffer size, collect the `n` highest values into a table.
  -- This allows you to get a sorted list of items out of a foldable.
  --
  -- `harvest` is useful for very large finite foldables, where you want
  -- to limit the number of results collected to a set of results that are "more
  -- important" (greater than) by some criteria.

  -- Make sure we have a useful value for `n`.
  -- If you don't provide `n`, `harvest` ends up being equivalent to
  -- collect, then sort.
  n = n or math.huge

  -- Fold a buffer table of items. We mutate this table, but no-one outside
  -- of the function sees it happen.
  local buffer = fold(foldable, function(buffer, item)
    table.insert(buffer, item)
    -- If buffer overflows by 100 items, sort and chop buffer.
    -- In other words, a sort/chop will happen every 100 items over the
    -- threshold... 100 is just an arbitrary batching number to avoid sorting
    -- too often or overflowing buffer... larger than 1, but not too large.
    if #buffer > n + 100 then chop_sorted_buffer(buffer, compare, n) end
    return buffer
  end, {})

  -- Sort and chop buffer one last time on the way out.
  return chop_sorted_buffer(buffer, compare, n)
end
exports.harvest = harvest

-- Zip items of b with a, using function `combine` to create value.
-- Returns new iterator with result of combining a and b.
-- Note that zip_with will only zip as far as the shortest list.
local function zip_with(foldable_a, foldable_b, combine)
  return function (step, seed)
    local a, b = foldable_ipairs(foldable_a), foldable_ipairs(foldable_b)
    local ai, left = a()
    local bi, right = b()

    while left and right do
      seed = step(seed, combine(left, right))
      ai, left = a()
      bi, right = b()
    end

    return seed
  end
end
exports.zip_with = zip_with

-- Wrap a cps function, returning a foldable function.
-- `cps_function` will have any additional arguments applied after callback.
-- Returns a foldable function.
local function from_cps(cps_function, ...)
  return function(step, seed)
    -- The `cps_function` is assumed to block until finished. If it doesn't,
    -- consider wrapping it in a coroutine.
    cps_function(function (v)
      -- Fold seed for each value passed to callback.
      seed = step(seed, v)
    end, unpack(arg))

    -- Return folded seed value.
    return seed
  end
end
exports.from_cps = from_cps

-- ## Design notes
--
-- Note that within Lua, there may only be one process operating at a given
-- time. It is impossible to have 2 processes operating in parallel within the
-- same Lua state. If you want that kind of thing, you have to turn to C, then
-- expose a Lua API of some kind.
--
-- See https://stackoverflow.com/questions/15943785/thread-priorities-in-lua/15944052#15944052
--
-- For this reason, all calls to fold are blocking.

return exports