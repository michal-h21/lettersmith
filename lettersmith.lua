local exports = {}

local lfs = require('lfs')
local attributes = lfs.attributes
local mkdir = lfs.mkdir

local list = require('colist')
local map = list.map
local zip_with = list.zip_with
local folds = list.folds
local collect = list.collect
local lazy = list.lazy

local util = require('util')
local merge = util.merge
local contains_any = util.contains_any

local path = require('path')

local headmatter = require('headmatter')

local function location_exists(location)
  -- Check if a location (file/directory) exists
  -- Returns boolean
  local f = io.open(location, "r")
  if f ~= nil then io.close(f) return true else return false end
end
exports.location_exists = location_exists

local function is_dir(path)
  return attributes(path, "mode") == "directory"
end
exports.is_dir = is_dir

local function is_file(path)
  return attributes(path, "mode") == "file"
end
exports.is_file = is_file

local function mkdir_if_missing(location)
  if location_exists(location) then
    return true
  else
    return mkdir(location)
  end
end

local function mkdir_deep(location)
  -- Create deeply nested directory at `location`.
  -- Returns `true` on success, or `nil, message` on failure.
  local parts = path.parts(location)

  -- Need to convert parts (table) to generator. @todo perhaps change
  -- parts to return generator?
  local dirpaths = folds(lazy(parts), function (seed, part)
    if seed == "" then return part else return seed .. "/" .. part end
  end, "")

  for _, dirpath in dirpaths do
    local is_success, message = mkdir_if_missing(dirpath)
    if not is_success then return is_success, message end
  end

  return true
end

local function walk_and_yield_filepaths(dirpath)
  for f in lfs.dir(dirpath) do
    local filepath = path.join(dirpath, f)

    if is_file(filepath) then
      -- @TODO might consider yielding useful numbered key here.
      coroutine.yield("Filepath", filepath)
    elseif is_dir(filepath) and f ~= '.' and f ~= '..' then
      walk_and_yield_filepaths(filepath)
    end
  end
end

local function walk_filepaths(dirpath)
  return coroutine.wrap(function () walk_and_yield_filepaths(dirpath) end)
end
exports.walk_filepaths = walk_filepaths

local function read_entire_file(filepath)
  -- Read entire contents of file and return as string.
  -- Will return string, or throw error if file can not be read.
  local f = assert(io.open(filepath, "r"))
  local contents = f:read("*all")
  f:close()
  return contents
end
exports.read_entire_file = read_entire_file

local function write_entire_file(filepath, contents)
  local f, message = io.open(filepath, "w")

  if f == nil then return f, message end

  f:write(contents)

  return f:close()
end
exports.write_entire_file = write_entire_file

local function write_entire_file_deep(filepath, contents)
  -- Write entire contents to file at deep directory location.
  -- This function will make sure all the necessary directories exist before
  -- creating the file.
  local basename, dirs = path.basename(filepath)
  local d, message = mkdir_deep(dirs)

  if d == nil then return d, message end

  return write_entire_file(filepath, contents)
end

local function to_doc(s)
  -- Get YAML table and contents from headmatter parser
  local head, contents = headmatter.parse(s)
  -- Since head is a new table, go ahead and mutate it, setting contents
  -- as field.
  head.contents = contents
  return head
end

-- A convenience function for writing renderers.
-- Provide a list of file extensions and a render function.
-- Returns a mapping function that will render all matching files in `docs`,
-- returning new generator list of rendered `docs`.
local function renderer(exts, render)
  return function (docs)
    return map(docs, function (doc)
      -- Skip docs not matching extension
      if not contains_any(doc.relative_filepath, exts) then return doc end

      -- Render contents
      local rendered = render(doc.contents)

      -- Return new shallow-copied doc with rendered contents
      return merge(doc, {
        contents = rendered
      })
    end)
  end
end
exports.renderer = renderer

local function docs(dirpath)
  -- Walk directory, creating doc objects from files.
  -- Returns a generator function of doc objects.
  -- Warning: generator may only be consumed once! If you need to consume it
  -- more than once, call `docs` again, or use `collect` to load all docs into
  -- an array table.

  local filepaths = walk_filepaths(dirpath)

  return map(filepaths, function (filepath)
    -- Read all filepaths into strings.
    -- Parse strings into doc objects.
    local doc = to_doc(read_entire_file(filepath))

    -- Relativize filepaths... This is a bit of a cludge. I would prefer to have
    -- absolute filepaths at all times, but relativized is so useful because it
    -- can be used for URLs too.
    -- @fixme this should be a proper relativize function. Lots of assumptions
    -- being made here.
    local relative_filepath = string.gsub(filepath, dirpath .. "/", "")

    -- Set relative_filepath on doc
    doc.relative_filepath = relative_filepath

    return doc
  end)
end
exports.docs = docs

-- @FIXME have to create files/directories when they don't exist.
local function build(docs, dirpath)
  for _, doc in docs do
    local filepath = path.join(dirpath, doc.relative_filepath)
    assert(write_entire_file_deep(filepath, doc.contents))
  end
end
exports.build = build

return exports