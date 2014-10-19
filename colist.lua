--[[
Basic higher-order list functions for lazy lists based on coroutines.

@todo I need a good name for these things.
* They're really generators, but I don't want to confuse them with Python's
  yield-based generators.
* Streams... streams are usually push data structures. These are pull.
  But I think Lisps streams work like this.
* Signals... they aren't really reactive signals (which are push data structures)
* Wires: not a common name.

All functions return transformed co-routine generator lists -- functions that
will yield a value each time they are called. Note that these coroutine lists
do not yield key, value tuples, but only value.

All of the higher-order functions can consume any function that returns a value
when invoked.

Co-routine lists are stateful (they don't take any arguments) and can only be
consumed once, at which point they become dead.

If you need to consume a list multiple times you have a couple of options:

- `collect()` will take a coroutine list and return a list table. Note that this
  means the whole list will now be in-memory, so it won't work for
  infinite lists.
- Create another coroutine list. They are cheap to create and use, so whatever
  you did to create the first one, you can do again.
]]--

local exports = {}

local function values(t)
  -- Convert table `t` into stateful generator coroutine that yields values of
  -- table. Unfortunately, you can't pass the result of `ipairs` as a
  -- first-class value, because it requires the context provided by the
  -- for loop. Our answer is to provide `values` that will allow you to iterate
  -- over the items in a table with a stateful coroutine that can be passed
  -- around to other functions.
  return coroutine.wrap(function()
    for _, v in ipairs(t) do coroutine.yield(v) end
  end)
end
exports.values = values

local function fold(colist, step, seed)
  -- Iterate over items, returning value folded from `seed`.
  for v in colist do seed = step(seed, v) end
  return seed
end
exports.fold = fold

local function folds(colist, step, seed)
  -- Iterate over items, returning generator which will yield every permutation
  -- folded from `seed`.
  return coroutine.wrap(function ()
    for v in colist do
      seed = step(seed, v)
      coroutine.yield(seed)
    end
  end)
end
exports.folds = folds

-- One-off function that wraps table.insert to make its order of magic args
-- play nicely with fold.
local function iinsert(t, v) table.insert(t, v) return t end

local function collect(colist)
  -- Collect all values of iterator into table.
  -- Note that since generators are lazy "pull" data structures,
  -- they can be infinite. Dumping an infinite generator into a table
  -- will exhaust memory. Be smart.
  -- Returns a new array table containing all values from generator.
  return fold(colist, iinsert, {})
end
exports.collect = collect

local function map(colist, transform)
  return coroutine.wrap(function ()
    for v in colist do coroutine.yield(transform(v)) end
  end)
end
exports.map = map

local function filter(colist, predicate)
  return coroutine.wrap(function ()
    for v in colist do
      if predicate(v) then coroutine.yield(v) end
    end
  end)
end
exports.filter = filter

local function reject(colist, predicate)
  return coroutine.wrap(function ()
    for v in colist do
      if not predicate(v) then coroutine.yield(v) end
    end
  end)
end
exports.reject = reject

local function zip_with(a, b, combine)
  -- Zip items of b with a, using function `combine` to create value.
  -- Returns new iterator with result of combining a and b.
  -- Note that zip_with will only zip as far as the shortest list.
  return coroutine.wrap(function ()
    local x, y = a(), b()

    while x and y do
      coroutine.yield(combine(x, y))
      x, y = a(), b()
    end
  end)
end
exports.zip_with = zip_with

local function concat(a, b)
  return coroutine.wrap(function ()
    for v in a do coroutine.yield(v) end
    -- Pick up `b` when `a` is exhausted.
    for v in b do coroutine.yield(v) end
  end)
end
exports.concat = concat

--[[
local function take(next, n)
  -- @TODO
end
exports.take = take

local function take_while(next, predicate)
  -- @TODO
end
exports.take_while = take_while
]]--

return exports