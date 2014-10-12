local lfs = require('lfs')
local attributes = lfs.attributes

local listable = require('listable')
local map = listable.map
local zip_with = listable.zip_with

local headmatter = require('headmatter')

local exports = {}

local function is_dir(path)
  return attributes(path, "mode") == "directory"
end
exports.is_dir = is_dir

-- @fixme will need to implement a path helper function to make this
-- work properly. Right now making terrible assumptions about path not being
-- trailing slashed, being valid subpath without resolution etc.
local function join_paths(a, b)
  return a .. '/' .. b
end
exports.join_paths = join_paths

local function walk_and_insert_filepaths(t, path)
  for f in lfs.dir(path) do
    local filepath = join_paths(path, f)
    if f == '.' or f == '..' then
      -- do nothing
    elseif is_dir(filepath) then
      walk_and_insert_filepaths(t, filepath)
    else
      table.insert(t, filepath)
    end
  end
  return t
end

local function walk_filepaths(path)
  return walk_and_insert_filepaths({}, path)
end
exports.walk_filepaths = walk_filepaths

local function read_file_to_end(filepath)
  -- Read entire contents of file and return as string.
  -- Will return string, or throw error if file can not be read.
  local f = assert(io.open(filepath, "r"))
  local contents = f:read("*all")
  f:close()
  return contents
end
exports.read_file_to_end = read_file_to_end

function to_doc(string)
  -- Get YAML table and contents from headmatter parser
  local head, contents = headmatter.parse(string)
  -- Since head is a new table, go ahead and mutate it, setting contents
  -- as field.
  head.contents = contents
  return head
end

function set_relative_filepath(doc, relative_filepath)
  -- Used to set filepath on documents in `docs` function.
  -- Not terribly useful in a broad context.
  doc.relative_filepath = relative_filepath
  return doc
end

-- @TODO still need to handle non-text-files separately. We don't want them
-- being templated after all. Then again, using a template meta should take
-- care of it.
local function docs(path)
  local filepaths = walk_filepaths(path)

  -- Read all filepaths into strings.
  local filestrings = map(filepaths, read_file_to_end)

  -- Parse strings into doc objects. These docs are orphaned because they
  -- have no `relative_filepath` field.
  local orphaned_docs = map(filestrings, to_doc)

  -- Relativize filepaths... This is a bit of a cludge. I would prefer to have
  -- absolute filepaths at all times, but relativized is so useful because it
  -- can be used for URLs too.
  local relative_filepaths = map(filepaths, function (filepath)
    -- @fixme this should be a proper relativize function. Lots of assumptions
    -- being made here.
    return string.gsub(filepath, path .. "/", "")
  end)

  -- Set relative filepath on docs and return
  return zip_with(orphaned_docs, relative_filepaths, set_relative_filepath)
end
exports.docs = docs

function build(path, docs)
end

return exports