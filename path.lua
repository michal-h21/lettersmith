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
  -- If your path contains traversals, you probably want to use `path.normalize`
  -- before passing to shift, since traversals will be considered parts of the
  -- path as well.

  -- Special case: if path starts with slash, it is a root path and slash has
  -- value. Return slash, along with rest of string.
  if s:find("^/") then return "/", s:sub(2) end

  local i, j = s:find('/')

  if i == nil then return s
  else return s:sub(1, i - 1), s:sub(j + 1) end
end

function path.parts(s)
  -- Get all parts of path as list table.
  local head, rest = "", s
  local t = {}

  repeat
    head, rest = path.shift(rest)
    table.insert(t, head)
  until rest == nil

  return t
end

-- Return the portion at the end of a path.
function path.basename(path_string)
  -- Get all parts of path as list table.
  local head, rest = "", path_string

  repeat
    head, rest = path.shift(rest)
  until rest == nil

  -- @fixme I think the way I calculate the rest of the path may be too naive.
  -- Update: it is. It doesn't take into account cases where you don't have a
  -- basename.
  return head, path_string:sub(0, #path_string - #head - 1)
end

function path.remove_extension(path_string)
  -- @todo let's deprecate this. It's redundant to have it when we could use
  -- path.extension plus a gsub or plain string sub.
  return path_string:gsub("%.%w+$", "")
end

function path.extension(path_string)
  local dot_i = path_string:find("%.[^.]+$")
  if not dot_i then return "" end
  return path_string:sub(dot_i)
end

function path.has_extension(location, extension)
  return location:find("%." .. extension .. "$") ~= nil
end

function path.has_any_extension(location, extensions)
  for _, extension in ipairs(extensions) do
    if path.has_extension(location, extension) then return true end
  end
  return false
end

return path