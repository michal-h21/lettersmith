--[[
A tiny library for working with paths. Tiny, because it is simple.

Only Unix-style paths are supported. Windows-style `\` are not handled.
My hypothesis is that it's less error-prone for a path library to support a
consistant API surface. If you need Windows paths, you can write conversion
functions that will let you switch from Win to Unix and back.
]]--

local path = {}

function path.remove_trailing_slash(s)
  -- Remove trailing slash from string. Will not remove slash if it is the
  -- only character in the string.
  return s:gsub('(.)%/$', '%1')
end

local function resolve_double_slashes(s)
  -- Resolution is a simple case of replacing double slashes with single.
  return s:gsub('%/%/', '/')
end

local function make_same_dir_explicit(s)
  if s == "" then return "." else return s end
end

local function resolve_dir_traversals(s)
  -- Resolves ../ and ./ directory traversals.
  -- Takes a path as string and returns resolved path string.

  -- First, resolve `../`. It needs to be handled first because `./` also
  -- matches `../`

  -- Watch for illegal traversals above root.
  -- For these cases, simply return root.
  -- /../ -> /
  if (s:find("^%/%.%.") ~= nil) then return "/" end

  -- Leading double dots should not be messed with.
  -- Replace leading dots with token so we don't accidentally replace it.
  s = s:gsub('^%.%.', "<LEADING_DOUBLE_DOT>")

  -- Elsewhere, remove double dots as well as directory above.
  s = s:gsub('[^/]+%/%.%.%/?', '')

  -- Next, resolve `./`.

  -- Remove single ./ from beginning of string
  s = s:gsub("^%.%/", "")

  -- Remove single ./ elsewhere in string
  -- Note: if we didn't do ../ subsitution earlier, this naive pattern would
  -- cause problems. Future me: don't introduce a bug by running this before
  -- ../ subsitution.
  s = s:gsub("%.%/", "")

  -- Remove single /. at end of string
  s = s:gsub("%/%.$", "")

  -- Bring back any leading double dots.
  s = s:gsub('<LEADING_DOUBLE_DOT>', "..")

  -- The patterns above can leave behind trailing slashes. Trim them.
  s = path.remove_trailing_slash(s)

  -- If string ended up empty, return "."
  s = make_same_dir_explicit(s)

  return s
end

function path.normalize(s)
  --[[
  /foo/bar          -> /foo/bar
  /foo/bar/         -> /foo/bar
  /foo/../          -> /
  /foo/bar/baz/./   -> /foo/bar/baz
  /foo/bar/baz/../  -> /foo/bar
  ..                -> ..
  /..               -> /
  /../../           -> /
  ]]--
  s = resolve_double_slashes(s)
  s = resolve_dir_traversals(s)
  return s
end

function path.join(a, b)
  return path.normalize(path.normalize(a) .. '/' .. path.normalize(b))
end

function path.shift(s)
  -- Return the highest-level portion of a path (it's a split on `/`), along
  -- with the rest of the path string.

  -- @fixme this function works but is still a bit naive. Maybe path.normalize
  -- first?

  local i = s:find('/')

  if i == nil then return s end

  -- Return head, the rest
  local head, rest = s:sub(1, i), s:sub(i + 1)
  return path.remove_trailing_slash(head), rest
end

-- @todo path.parts generator function
function path.parts(s)
  local head, rest = "", s

  return function ()
    head, rest = path.shift(rest)
    return head, rest
  end
end

return path