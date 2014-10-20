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
  -- Convert table `t` into an event stream that will invoke `callback` with
  -- each value in table `t`.
  return function (callback)    
    for _, v in ipairs(t) do callback(v) end
  end
end
exports.values = values

local function lazily(events)
  -- Wrap an event function in a coroutine, making it a "pull" data structure
  -- rather than a "push" data structure.
  return coroutine.wrap(function ()
    events(coroutine.yield)
  end)
end
exports.lazily = lazily

local function map(events, transform)
  return function (callback)
    events(function (v)
      callback(transform(v))
    end)
  end
end
exports.map = map

local function filter(events, predicate)
  return function (callback)
    events(function (v)
      if predicate(v) then callback(v) end
    end)
  end
end
exports.filter = filter

local function reject(events, predicate)
  return function (callback)
    events(function (v)
      if not predicate(v) then callback(v) end
    end)
  end
end
exports.reject = reject

local function folds(events, step, seed)
  -- Iterate over items, returning generator which will yield every permutation
  -- folded from `seed`.
  return function (callback)
    events(function (v)
      seed = step(seed, v)
      callback(seed)
    end)
  end
end
exports.folds = folds

local function merge(a, b)
  -- Merge values from 2 streams into a single stream, ordered by time.
  -- Returns new stream.
  return function(callback)
    a(callback)
    b(callback)
  end
end
exports.merge = merge

local function concat(a, b)
  -- Merge values from 2 streams into a single stream, ordered by time.
  -- Returns new stream.
  return function(callback)
    local _a, _b = lazily(a), lazily(b)
    -- First consume lazy version of event stream `a`
    for v in _a do callback(v) end
    -- Then, consume lazy version of event stream `b`
    for v in _b do callback(v) end
  end
end
exports.concat = concat

local function zip_with(events_a, events_b, combine)
  -- Zip items of b with a, using function `combine` to create value.
  -- Returns new iterator with result of combining a and b.
  -- Note that zip_with will only zip as far as the shortest list.
  return function (callback)
    local a, b = lazily(events_a), lazily(events_b)
    local x, y = a(), b()

    while x and y do
      callback(combine(x, y))
      x, y = a(), b()
    end
  end
end
exports.zip_with = zip_with

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

local function fold(next, step, seed)
  -- Iterate over stateless iterator function, returning value folded
  -- from `seed`.
  for v in next do seed = step(seed, v) end
  return seed
end
exports.fold = fold

local function append(t, v) table.insert(t, v) return t end
exports.append = append

local function collect(events)
  -- Collect all values of events into a table.
  return fold(lazily(events), append, {})
end
exports.collect = collect

return exports