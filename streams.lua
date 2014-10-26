-- Streams https://en.wikipedia.org/wiki/Stream_%28computing%29
-- Lazy or greedy stream programming with coroutines.
--
-- A `stream` is any function of shape `stream(callback)` where `callback`
-- function is called by stream function with values repeatedly until exausted.
--
-- Stream transformations consume a stream function, returning a new stream
-- function representing transformed/filtered values (see `map` for a good
-- example. This actually just transforms the function. No actual work happens
-- until you invoke the resulting function with a callback. At that point, the
-- stream will be "turned on" and "push" values to callback.
--
-- Streams can be made "pull" data structures by transforming with
-- `to_coroutine(stream)`. This will return a coroutine that may be consumed by
-- for loops.

local exports = {}

local function values(t)
  -- Convert table `t` into an stream that will invoke `callback` with
  -- each value in table `t`.
  -- Return stream function.
  return function (callback)
    -- Call callback with every value in table.
    for _, v in ipairs(t) do callback(v) end
  end
end
exports.values = values

local function to_coroutine(stream)
  -- Wrap a stream function in a coroutine, making it a "pull" data structure
  -- rather than a "push" data structure.
  --
  -- Streams can be made "pull" data structures by transforming with
  -- `to_coroutine(stream)`. This will return a coroutine that may be consumed by
  -- for loops.
  --
  --     for v in to_coroutine(stream) do print(v) end
  --
  -- This will block for each value of stream.
  --
  -- Return a coroutine iterator function. These can only be consumed once.
  return coroutine.wrap(function ()
    stream(coroutine.yield)
  end)
end
exports.to_coroutine = to_coroutine

local function map(stream, transform)
  return function (callback)
    stream(function (v)
      callback(transform(v))
    end)
  end
end
exports.map = map

local function filter(stream, predicate)
  return function (callback)
    stream(function (v)
      if predicate(v) then callback(v) end
    end)
  end
end
exports.filter = filter

local function reject(stream, predicate)
  return function (callback)
    stream(function (v)
      if not predicate(v) then callback(v) end
    end)
  end
end
exports.reject = reject

local function folds(stream, step, seed)
  -- Iterate over items, returning generator which will yield every permutation
  -- folded from `seed`.
  return function (callback)
    stream(function (v)
      seed = step(seed, v)
      callback(seed)
    end)
  end
end
exports.folds = folds

local function merge(stream_a, stream_b)
  -- Merge values from 2 streams into a single stream, ordered by time.
  -- Returns new stream.
  return function(callback)
    stream_a(callback)
    stream_b(callback)
  end
end
exports.merge = merge

local function concat(stream_a, stream_b)
  -- Merge values from 2 streams into a single stream, ordered by time.
  -- Returns new stream.
  return function(callback)
    local a, b = to_coroutine(stream_a), to_coroutine(stream_b)
    -- First consume lazy version of stream `a`
    for v in a do callback(v) end
    -- Then, consume lazy version of stream `b`
    for v in b do callback(v) end
  end
end
exports.concat = concat

local function zip_with(stream_a, stream_b, combine)
  -- Zip items of b with a, using function `combine` to create value.
  -- Returns new iterator with result of combining a and b.
  -- Note that zip_with will only zip as far as the shortest list.
  return function (callback)
    local a, b = to_coroutine(stream_a), to_coroutine(stream_b)
    local x, y = a(), b()

    while x and y do
      callback(combine(x, y))
      x, y = a(), b()
    end
  end
end
exports.zip_with = zip_with

local function take(stream, n)
  -- Take up to `n` number of items from stream.
  -- Returns a new stream containing at most `n` items.

  -- Just return original stream if number of items to take is infinite.
  if n == math.huge then return stream end

  return function(callback)
    local yield_item = to_coroutine(stream)

    repeat
      local item = yield_item()
      n = n - 1
      callback(item)
    until n < 1 or item == nil
  end
end
exports.take = take

--[[

local function take_while(next, predicate)
  -- @TODO
end
exports.take_while = take_while
]]--

local function fold(stream, step, seed)
  -- Iterate over an event stream, returning value folded
  -- from `seed`.
  for v in to_coroutine(stream) do seed = step(seed, v) end
  return seed
end
exports.fold = fold

local function append(t, v)
  -- Append a value to a table, mutating table.
  -- Returns mutated table.
  table.insert(t, v)
  return t
end
exports.append = append

local function collect(stream)
  -- Collect all values of stream into a table.
  return fold(stream, append, {})
end
exports.collect = collect

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

local function skim(stream, compare, n)
  -- Skim the cream off the top... given a stream, a comparison function
  -- and a buffer size, collect the `n` highest values into a table.
  -- This allows you to get a sorted list of items out of a stream.
  --
  -- You'll have to wait for the stream to complete to get a return result,
  -- so infinite streams or streams with long delays are not advised.
  -- However, `skim` is useful for very large finite streams, where you want to
  -- limit the number of results collected to a set of results that are "more
  -- important" (greater than) by some criteria.

  -- Make sure we have a useful value for `n`.
  -- If you don't provide `n`, `skim` ends up being equivalent to
  -- collect, then sort.
  n = n or math.huge

  -- Since streams are time-based, the only other options for sorting streams
  -- are:
  -- * Collect everything.
  -- * A stream of buffer tables over time (perhaps batched)
  -- * Something exactly like skim, but cause `fold` to return a future
  --   so main program is not blocked until necessary.

  -- Fold a buffer table of items. We mutate this table, but no-one outside
  -- of the function sees it happen.
  local buffer = fold(stream, function(buffer, item)
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
exports.skim = skim

return exports