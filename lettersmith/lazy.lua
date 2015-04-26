local exports = {}

local transducers = require("lettersmith.transducers")
local transduce = transducers.transduce
local reduce = transducers.reduce
local append = transducers.append

local function step_yield(_, v)
  coroutine.yield(v)
  return v
end

-- Apply an `xform` function to an iterator.
-- Returns a new coroutine iterator that is the result of applying `xform`
-- to elements in iterator.
local function transform(xform, iter, t, i)
  return coroutine.wrap(function ()
    transduce(xform, step_yield, nil, iter, t, i)
  end)
end
exports.transform = transform

-- Given a transducers transform function, will return a function that takes
-- an iterator and returns a coroutine iterator representing the transformation
-- of items in that iterator.
local function transformer(xform)
  -- Take any iterator
  return function (iter, ...)
    -- And lazily transform it, returning a coroutine iterator.
    return transform(xform, iter, ...)
  end
end
exports.transformer = transformer

-- Concatenate many stateful iterators together into a single coroutine
-- iterator. Returns coroutine iterator.
local function concat(...)
  local iters = {...}
  return coroutine.wrap(function ()
    for _, iter in ipairs(iters) do
      reduce(step_yield, nil, iter)
    end
  end)
end
exports.concat = concat

-- Partition an iterator into "chunks", returning an iterator of tables
-- containing `n` items each.
local function partition(n, iter, t, i)
  local function step_partition(t_chunk, input)
    if #t_chunk < n then
      return append(t_chunk, input)
    else
      -- Yield table when it is full of `n` items.
      coroutine.yield(t_chunk)
      return {input}
    end
  end

  return coroutine.wrap(function()
    coroutine.yield(reduce(step_partition, {}, iter, t, i))
  end)
end
exports.partition = partition

local function step_delay_yield(prev, curr)
  if prev then
    coroutine.yield(prev)
  end
  return curr
end

-- Delay all items in an iterable by one step.
-- In other words, coroutine will block until second item arrives, and then
-- begin yielding the `n - 1` item.
--
-- This is useful if you need to mutate left and right items in an iterator
-- with reduce. By using `delay` you can make sure no one sees the mutation
-- happen.
local function delay(iter, t, i)
  return coroutine.wrap(function ()
    local last = reduce(step_delay_yield, nil, iter, t, i)
    coroutine.yield(last)
  end)
end
exports.delay = delay

return exports
