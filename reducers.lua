-- A reinterpretation of Clojure Reducers for Lua.
--
-- Ordinary reduce is a function of shape:
--
--    (step, seed, table) -> value
--
-- A reducer is similar... it is a function of shape:
--
--    (step, seed) -> value
--
-- Similar to reduce, it produces a value from a stepping function and a seed.
-- Unlike reduce, it does not take a collection: it contains its own state and
-- knows how to produce values by itself. This means it is free to generate
-- values in any way it likes.
--
-- In addition, this library contains functions that are able to transform
-- reducible functions, returning a new reducible function. You may recognize
-- them: `map`, `filter`, etc. These functions transform lazily, so no
-- intermediate collections are created for transformations. This is can be
-- crazy fast for large collections.
--
-- No actual work is done until you reduce the reducible function:
--
--     reduce(x, step, seed)
--
-- See http://clojure.com/blog/2012/05/15/anatomy-of-reducer.html for more on
-- this idea.
--
-- Note that we actually use `transducers` to do the actual logic of step
-- function transformations. Reducers just wraps it to provide a
-- "collection-like" API.

local exports = {}

local xf = require("transducers")
local reduce_iter = xf.reduce

-- Create a reducible function from an iterator.
--
--     from_iter(ipairs(t))
local function from_iter(iter, state, at)
  return function(step, seed)
    return reduce_iter(step, seed, iter, state, at)
  end
end
exports.from_iter = from_iter

-- Create a reducible function from a table.
--
--     from_table(t)
local function from_table(t)
  return from_iter(ipairs(t))
end
exports.from_table = from_table

local function step_and_yield(_, v)
  coroutine.yield(v)
end

-- Create a coroutine iterator from a reducible function.
--
--     y = to_iter(reducible)
--     for x in y print(x) end
local function to_iter(reducible)
  return coroutine.wrap(function () reduce(step_and_yield, reducible) end)
end
exports.to_iter = to_iter

-- Append a value to a table, returning table.
local function append(t, v)
  table.insert(t, v)
  return t
end
exports.append = append

-- Collect all values of a reducible function into an indexed table.
local function into(t, reducible)
  return reducible(append, t)
end
exports.into = into

-- Transform a reducible function using a transducer `xform` function.
-- Returns transformed reducible function.
local function transform(xform, reducible)
  return function(step, seed)
    return reducible(xform(step), seed)
  end
end
exports.transform = transform

-- A short-cut function for creating reducible transforming functions of shape:
--
--     (x, reducible) -> reducible
--
-- We use it below to define `map`, `filter`, etc.
local function transformer(xform_factory)
  return function(option, reducible)
    return transform(xform_factory(option), reducible)
  end
end

-- Map values in a reducible function
--
--     map(a2b, reducible)
local map = transformer(xf.map)
exports.map = map

-- Filter values in a reducible function that match predicate function.
--
--     filter(predicate, reducible)
local filter = transformer(xf.filter)
exports.filter = filter

-- Reject values in a reducible function that match predicate function.
--
--     reject(predicate, reducible)
local reject = transformer(xf.reject)
exports.reject = reject

-- Take `n` values from a reducible function.
--
--     take(3, reducible)
local take = transformer(xf.take)
exports.take = take

-- Take values from a reducible function until predicate returns false.
--
--     take(predicate, reducible)
local take_while = transformer(xf.take_while)
exports.take_while = take_while

-- Dedupe adjacent values that are the same.
--
--     dedupe(reducible)
local function dedupe(reducible)
  return transform(xf.dedupe, reducible)
end
exports.dedupe = dedupe

-- Transform reducible of values into reducible of reductions.
--
--     reductions(permutate, x, reducible)
local function reductions(step, seed, reducible)
  return transform(xf.reductions(step, seed), reducible)
end
exports.reductions = reductions

-- Concatenate two reducible things together.
-- `reducible_a` will be reduced in full before `reducible_b`.
-- The result is as if the items in `reducible_b` were at the end of
-- `reducible_a`.
local function concat(reducible_a, reducible_b)
  return function(step, seed)
    seed = reducible_a(step, seed)
    seed = reducible_b(step, seed)
    return seed
  end
end
exports.concat = concat

return exports

