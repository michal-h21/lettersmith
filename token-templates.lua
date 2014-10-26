local exports = {}

-- A simple template renderer that takes a string with optional `:key` tokens
-- and renders replacements using associated values in `context_table`.
--
-- `context_table` contains token, replacement pairs. Keys do not need to
-- contain :.
local function render(url_template_string, context_table)
  return url_template_string:gsub(":([%w-_]+)", function(key)
    return context_table[key] or ""
  end)
end
exports.render = render

return exports