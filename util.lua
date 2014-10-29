--[[
Table utilities: the goodies you might wish were part of the standard
table library.
]]--

local exports = {}

local function extend(a, b)
  -- Set values of b on a, mutating a
  -- Returns a
  for k, v in pairs(b) do a[k] = v end
  return a
end
exports.extend = extend

local function merge(a, b)
  -- Combine keys and values of a and b in new table.
  -- b's keys will overwrite a's keys when a conflict arises.
  -- Returns new table.
  return extend(extend({}, a), b)
end
exports.merge = merge

local function shallow_copy(t)
  return extend({}, t)
end
exports.shallow_copy = shallow_copy

local function set(t, k, v)
  t[k] = v
  return t
end
exports.set = set

local function fold(t, step, seed)
  -- Fold a value from a `seed` using `step` function.
  -- Call `step` with value and index, updating `seed` with return value.
  for i, v in ipairs(t) do seed = step(seed, v, i) end
  return seed
end
exports.fold = fold

local function map(t, transform)
  -- Map all values of table using function `transform`.
  -- Returns new indexed table.
  return fold(t, function (out, v, i)
    -- Set transformed value on `out` table at `i` index.
    return set(out, transform(v), i)
  end, {})
end
exports.map = map

return exports