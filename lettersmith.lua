local exports = {}

local list = require('colist')
local map = list.map
local zip_with = list.zip_with
local folds = list.folds
local collect = list.collect
local lazy = list.lazy

local util = require('util')
local merge = util.merge

local path = require('path')

local file_utils = require('file-utils')
local children = file_utils.children
local is_file = file_utils.is_file
local is_dir = file_utils.is_dir
local location_exists = file_utils.location_exists
local write_entire_file_deep = file_utils.write_entire_file_deep
local read_entire_file = file_utils.read_entire_file
local remove_recursive = file_utils.remove_recursive

local headmatter = require('headmatter')

-- A convenience function for writing renderers.
-- Provide a list of file extensions and a render function.
-- Returns a mapping function that will render all matching files in `docs`,
-- returning new generator list of rendered `docs`.
local function renderer(src_extensions, rendered_extension, render)
  return function (docs)
    return map(docs, function (doc)
      -- @todo should we throw an error if extensions have `.` included?
      if not path.has_any_extension(doc.relative_filepath, src_extensions) then
        return doc
      end

      -- Render contents
      local rendered = render(doc.contents)

      -- Replace file extension
      local relative_filepath = string.gsub(
        doc.relative_filepath,
        "\.[^.]+$",
        "." .. rendered_extension
      )

      -- Return new shallow-copied doc with rendered contents
      return merge(doc, {
        contents = rendered,
        relative_filepath = relative_filepath
      })
    end)
  end
end
exports.renderer = renderer

local function walk_and_yield_filepaths(dirpath)
  for f in children(dirpath) do
    local filepath = path.join(dirpath, f)

    if is_file(filepath) then
      coroutine.yield(filepath)
    elseif is_dir(filepath) then
      walk_and_yield_filepaths(filepath)
    end
  end
end

local function walk_filepaths(dirpath)
  return coroutine.wrap(function () walk_and_yield_filepaths(dirpath) end)
end
exports.walk_filepaths = walk_filepaths

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
    local filestring = read_entire_file(filepath)

    -- Get YAML meta table and contents from headmatter parser.
    -- We'll use the meta table as the doc object.
    local doc, contents = headmatter.parse(filestring)

    -- Since doc is a new table, go ahead and mutate it, setting contents
    -- as field.
    doc.contents = contents

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
  -- @TODO First remove build dir if it still exists.
  -- This needs to be recursive, since rmdir will refuse to delete dirs that
  -- aren't empty.
  if location_exists(dirpath) then assert(remove_recursive(dirpath)) end

  -- Then generate files.
  for doc in docs do
    local filepath = path.join(dirpath, doc.relative_filepath)
    assert(write_entire_file_deep(filepath, doc.contents))
  end
end
exports.build = build

return exports
