local exports = {}

local function split(s, delimiter)
  local result = {}
  -- Note that gmatch matches the "non-delimiter text". So we'll append
  -- a delimiter as a trick
  for match in (s..delimiter):gmatch("(.-)"..delimiter) do
    table.insert(result, match)
  end
  return result
end
exports.split = split

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

return exports