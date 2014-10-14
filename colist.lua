local exports = {}

local function lazy(table)
  -- Convert table into stateful generator coroutine.
  -- We need this because you can't pass stateless iterator functions as
  -- first-class values: they need table as argument and for loop seems to have
  -- a magic context that is lost when passing the function barrier.
  return coroutine.wrap(function()
    for i, v in ipairs(table) do coroutine.yield(i, v) end
  end)
end
exports.lazy = lazy

local function fold(iter, step, seed)
  -- Iterate over items in iterator, returning value folded from `seed`.
  for i, v in iter do seed = step(seed, v, i) end
  return seed
end
exports.fold = fold

-- One-off function that wraps table.insert to make its order of magic args
-- play nicely with fold.
function iinsert(t, v) table.insert(t, v) return t end

local function collect(next)
  -- Collect all values of iterator into table.
  -- Note that since generators are lazy "pull" data structures,
  -- they can be infinite. Dumping an infinite generator into a table
  -- will exhaust memory. Be smart.
  -- Returns a new array table containing all values from generator.
  return fold(next, iinsert, {})
end
exports.collect = collect

local function map(next, transform)
  -- Map iterable.
  -- Returns new generator with results of `transform`.
  return coroutine.wrap(function ()
    for i, v in next do coroutine.yield(i, transform(v)) end
  end)
end
exports.map = map

local function filter(next, predicate)
  -- Filter iterable.
  -- Returns new generator with only items that pass the `predicate` test.
  return coroutine.wrap(function ()
    for i, v in next do
      if predicate(v) then coroutine.yield(i, v) end
    end
  end)
end
exports.filter = filter

local function reject(next, predicate)
  -- Filter iterable.
  -- Returns new generator with only items that fail the `predicate` test.
  return coroutine.wrap(function ()
    for i, v in next do
      if not predicate(v) then coroutine.yield(i, v) end
    end
  end)
end
exports.reject = reject

local function zip_with(a, b, combine)
  -- Zip items of b with a, using function `combine` to create value.
  -- Returns new iterator with result of combining a and b.
  -- Note that zip_with will only zip as far as the shortest list.
  return coroutine.wrap(function ()
    local i = 0
    local xi, x = a()
    local yi, y = b()

    while x and y do
      coroutine.yield(i, combine(x, y))
      i = i + 1
      xi, x = a()
      yi, y = b()
    end
  end)
end
exports.zip_with = zip_with

local function concat(a, b)
  return coroutine.wrap(function ()
    -- We'll need to keep track of our own index variable since we're not going
    -- to use the one that the for loop hands us.
    local i = 0
    for _, v in a do
      i = i + 1
      coroutine.yield(i, v)
    end
    -- Pick up `b` when `a` is exhausted. Keep using same `i` variable.
    for _, v in b do
      i = i + 1
      coroutine.yield(i, v)
    end
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