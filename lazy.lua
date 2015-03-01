local exports = {}

local transducers = require("lettersmith.transducers")
local transduce = transducers.transduce
local reduce = transducers.reduce

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

return exports
