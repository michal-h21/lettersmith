local exports = {}

local function fold(table, step, out)
  for i, v in ipairs(table) do out = step(out, v, i) end
  return out
end
exports.fold = fold

-- Iterators http://www.lua.org/pil/7.1.html
-- Stateless iterators http://www.lua.org/pil/7.3.html
-- Can I make folds lazy?

-- local function lazy_map(next, transform)
--   -- this is great, but doesn't work for filter... or does it?
--   -- Also table is decoupled from next which I really don't like.
--   return function (t, i)
--     i, v = next(t, i)
--     if i ~= nil then
--       return i, transform(v)
--     else
--       return nil, nil
--     end
--   end
-- end

local function map(table, transform)
  return fold(table, function (out, v, i)
    out[i] = transform(v)
    return out
  end, {})
end
exports.map = map

local function filter(table, predicate)
  return fold(table, function (out, v, i)
    if predicate(v) then out[i] = v end
    return out
  end, {})
end
exports.filter = filter

local function reject(table, predicate)
  return fold(table, function (out, v, i)
    if not predicate(v) then out[i] = v end
    return out
  end, {})
end
exports.reject = reject

local function insert(t, v)
  -- Exactly like table.insert, but returns mutated table.
  table.insert(t, v)
  return t
end
exports.insert = insert

local function append(a, b)
  -- Concatenates table `a` to table `b`. Returns a new array table with values
  -- of `a` and `b`.
  return fold(b, insert, fold(a, insert, {}))
end
exports.append = append

local function zip_with(a, b, combine)
  -- Zip items of b with a, using function `combine` to create value.
  -- Returns new table with each value created by combine.
  return fold(a, function (t, v, i)
    return insert(t, combine(a[i], b[i]))
  end, {})
end
exports.zip_with = zip_with

return exports