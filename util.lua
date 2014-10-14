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

local function contains_any(s, patterns)
  for _, pattern in pairs(patterns) do
    local i = s:find(pattern)
    if i ~= nil then return true end
  end
  return false
end
exports.contains_any = contains_any

return exports