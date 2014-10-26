-- Support functions for Unix-esque path query strings with wildcards:
--
-- `hello/*.md` matches `hello/x.md` but not `hello/y/x.md`.
-- `hello/**.md` matches `hello/x.md` and `hello/y/x.md`.

local query = {}

function query.escape_pattern(pattern_string)
  -- Auto-escape all magic characters in a string.
  return pattern_string:gsub("[%-%.%+%[%]%(%)%$%^%%%?%*]", "%%%1")
end

function query.parse(query_string)
  -- Parses a path query string into a proper Lua pattern string that can be
  -- used with find and gsub.

  -- Replace double-asterisk and single-asterisk query symbols with
  -- temporary tokens.
  local tokenized = query_string
    :gsub("%*%*", "__DOUBLE_STAR__")
    :gsub("%*", "__SINGLE_STAR__")
  -- Then escape any magic characters.
  local escaped = query.escape_pattern(tokenized)
  -- Finally, replace tokens with true magic-character patterns.
  -- Double-asterisk will traverse any number of characters to make a match.
  -- single-asterisk will only traverse non-slash characters (i.e. in same dir).
  local pattern = escaped
    :gsub("__DOUBLE_STAR__", ".+")
    :gsub("__SINGLE_STAR__", "[^/]+")

  return pattern
end

return query