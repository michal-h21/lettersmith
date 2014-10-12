local yaml = require('yaml')

local exports = {}

local function split_headmatter(str)
  -- Split headmatter from "the rest of the content" in a string.
  -- Files may contain headmatter, but may also choose to omit it.
  -- Returns two strings, a headmatter string (which may or may not
  -- be empty) and the rest of the content string.

  -- Look for headmatter start tag.
  local headmatter_open_start, headmatter_open_end = str:find("%-+")

  -- If no headmatter is present, return an empty table and string
  if headmatter_open_start == nil or headmatter_open_start > 1 then
    return "", str
  end

  local headmatter_close_start, headmatter_close_end =
    str:find("%-+", headmatter_open_end + 1)

  local headmatter =
    str:sub(headmatter_open_end + 1, headmatter_close_start - 1)

  local rest = str:sub(headmatter_close_end + 1)

  return headmatter, rest
end
exports.split = split_headmatter

local function parse_headmatter(s)
  -- Split out headmatter from "the rest of the content" and parse into
  -- Lua table using YAML.
  -- If headmatter is not legit YAML, an error will be thrown.
  -- Returns table, string (parsed head matter, content)
  local headmatter, rest = split_headmatter(s)
  local head = yaml.load(headmatter) or {}
  return head, rest
end
exports.parse = parse_headmatter

return exports