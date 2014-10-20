local exports = {}

local list = require('colist')
local map = list.map
local fold = list.fold

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

local lfs = require("lfs")

local date = require("date")

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

local function walk_filepaths_cps(path_string, callback)
  for f in children(path_string) do
    local filepath = path.join(path_string, f)

    if is_file(filepath) then
      callback(filepath)
    elseif is_dir(filepath) then
      walk_filepaths_cps(filepath, callback)
    end
  end
end

local function emit_filepaths(path_string)
  return function(callback)
    walk_filepaths_cps(path_string, callback)
  end
end
exports.emit_filepaths = emit_filepaths

local function docs(path_string)
  -- Walk directory, creating doc objects from files.
  -- Returns a generator function of doc objects.
  -- Warning: generator may only be consumed once! If you need to consume it
  -- more than once, call `docs` again, or use `collect` to load all docs into
  -- an array table.

  local filepaths = emit_filepaths(path_string)

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

    -- Assign date field from modified file date, if it doesn't already exist.
    local date_string = doc.date or lfs.attributes(filepath, "modified")
    local date_iso = date(date_string):fmt("${iso}")
    doc.date = date_iso

    -- Relativize filepaths... This is a bit of a cludge. I would prefer to have
    -- absolute filepaths at all times, but relativized is so useful because it
    -- can be used for URLs too.
    -- @fixme this should be a proper relativize function. Lots of assumptions
    -- being made here.
    local relative_filepath = string.gsub(filepath, path_string .. "/", "")

    -- Set relative_filepath on doc
    doc.relative_filepath = relative_filepath

    return doc
  end)
end
exports.docs = docs

local function build(doc_stream, path_string)
  local start = os.time()

  if location_exists(path_string) then assert(remove_recursive(path_string)) end

  local number_of_files = fold(doc_stream, function (number_of_files, doc)
    local filepath = path.join(path_string, doc.relative_filepath)
    assert(write_entire_file_deep(filepath, doc.contents))
    return number_of_files + 1
  end, 1)

  local build_time = os.time() - start

  print("Done! Generated " .. number_of_files .. " files in " .. build_time .. 's.')
end
exports.build = build

return exports
