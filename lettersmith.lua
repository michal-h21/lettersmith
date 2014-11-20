local exports = {}

local transducers = require("transducers")
local apply_to = transducers.apply_to
local reduce = transducers.reduce

local lazily = require("lazily")

local path = require("path")

local file_utils = require("file_utils")
local children = file_utils.children
local is_file = file_utils.is_file
local is_dir = file_utils.is_dir
local location_exists = file_utils.location_exists
local write_entire_file_deep = file_utils.write_entire_file_deep
local read_entire_file = file_utils.read_entire_file
local remove_recursive = file_utils.remove_recursive

local lfs = require("lfs")

local date = require("date")

local headmatter = require("headmatter")

local function walk_file_paths_cps(callback, path_string)
  -- Recursively walk through directory at `path_string` calling
  -- `callback` with each file path found.
  for f in children(path_string) do
    local filepath = path.join(path_string, f)

    if is_file(filepath) then
      callback(filepath)
    elseif is_dir(filepath) then
      walk_file_paths_cps(callback, filepath)
    end
  end
end

-- Given `path_string` -- a path to a directory -- recursively walks through
-- directory and returns an iterator for all file paths.
-- Returns a coroutine iterator which may be consumed once.
function walk_file_paths(path_string)
  return coroutine.wrap(function ()
    walk_file_paths_cps(coroutine.yield, path_string)
  end)
end
exports.walk_file_paths = walk_file_paths

local function load_doc(base_path_string, relative_path_string)
  -- Load contents of a file as a document table.
  -- Returns a new document table containing:
  -- `date`, `contents`, plus any other properties defined in headmatter.

  -- Join base path and relative path into a full path string.
  local path_string = path.join(base_path_string, relative_path_string)

  -- @fixme get rid of assert in `read_entire_file`
  -- return early with error instead
  local file_string = read_entire_file(path_string)

  -- Get YAML meta table and contents from headmatter parser.
  -- We'll use the meta table as the doc object.
  local doc, contents_string = headmatter.parse(file_string)

  -- Since doc is a new table, go ahead and mutate it, setting contents
  -- as field.
  doc.contents = contents_string

  -- Assign date field from modified file date, if it doesn't already exist.
  local date_string = doc.date or lfs.attributes(path_string, "modified")
  doc.date = date(date_string):fmt("${iso}")

  -- Set relative_filepath on doc.
  -- Remove any leading slash so it is truly relative (not root relative).
  doc.relative_filepath = relative_path_string:gsub("^/", "")

  return doc
end
exports.load_doc = load_doc

local function docs(base_path_string)
  -- Walk directory, creating doc objects from files.
  -- Returns a coroutine iterator function good for each doc table.
  function path_to_doc(path_string)
    -- Remove the base path string to get the relative file path.
    local relative_path_string = path_string:sub(#base_path_string + 1)
    return load_doc(base_path_string, relative_path_string)
  end

  return lazily.map(path_to_doc, walk_file_paths(base_path_string))
end
exports.docs = docs

local function build(out_path_string, iter, state, at)
  -- Remove old build directory recursively.
  if location_exists(out_path_string) then
    assert(remove_recursive(out_path_string))
  end

  function write_and_tally(number_of_files, doc)
    -- Create new file path from relative path and out path.
    local file_path = path.join(out_path_string, doc.relative_filepath)
    assert(write_entire_file_deep(file_path, doc.contents or ""))
    return number_of_files + 1
  end

  -- Consume transformed doc iterator. Return a tally representing number
  -- of files written.
  return reduce(write_and_tally, 0, iter, state, at)
end
exports.build = build

-- Load, process and write all in a single function.
local function generate(in_path_string, out_path_string, ...)
  -- Transform documents using plugins, starting from left-most plugin and
  -- working our way right.
  local transformed_docs = reduce(apply_to, docs(in_path_string), ipairs(arg))
  return build(out_path_string, transformed_docs)
end
exports.generate = generate

return exports
