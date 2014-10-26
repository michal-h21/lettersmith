local exports = {}

-- A simple template renderer that takes a string with optional `:key` tokens
-- and renders replacements using associated values in `context_table`.
--
-- `context_table` contains token, replacement pairs.
--
-- Tokens start with a `:` and may be followed by any number of alphanumeric
-- characters or `_`.
local function render(url_template_string, context_table)
  return url_template_string:gsub(":([%w_]+)", function(key)
    return context_table[key] or ""
  end)
end
exports.render = render

return exports