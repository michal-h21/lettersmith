local exports = {}

local transducers = require("lettersmith.transducers")
local reduce = transducers.reduce
local map = transducers.map
local eduction = transducers.eduction
local collect = transducers.collect

local path = require("lettersmith.path")

local plugin_utils = require("lettersmith.plugin_utils")
local compare_by_file_path_date = plugin_utils.compare_by_file_path_date
local match_date_in_file_path = plugin_utils.match_date_in_file_path

local file_utils = require("lettersmith.file_utils")
local children = file_utils.children
local is_file = file_utils.is_file
local is_dir = file_utils.is_dir
local location_exists = file_utils.location_exists
local write_entire_file_deep = file_utils.write_entire_file_deep
local read_entire_file = file_utils.read_entire_file
local remove_recursive = file_utils.remove_recursive

local headmatter = require("lettersmith.headmatter")

-- Recursively walk through directory at `path_string` calling
-- `callback` with each file path found.
local function walk_file_paths_cps(callback, path_string)
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
-- directory for all file paths.
-- Returns a coroutine iterator.
local function walk_file_paths(path_string)
  return coroutine.wrap(function()
    walk_file_paths_cps(coroutine.yield, path_string)
  end)
end
exports.walk_file_paths = walk_file_paths

-- Get a sorted list of all file paths under a given `path_string`.
-- `compare` is a comparison function for `table.sort`.
-- By default, will sort file paths using `compare_by_file_path_date`.
-- Returns a Lua list table of file paths.
local function list_file_paths(path_string)
  -- Recursively walk through file paths. Collect result in table.
  local file_paths_table = collect(walk_file_paths(path_string))
  -- Sort our new table in-place, comparing by date.
  table.sort(file_paths_table, compare_by_file_path_date)
  return file_paths_table
end
exports.list_file_paths = list_file_paths

-- Load contents of a file as a document table.
-- Returns a new document table containing:
-- `date`, `contents`, plus any other properties defined in headmatter.
local function load_doc(base_path_string, relative_path_string)
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

  -- If doc doesn't have a date field, try to extract a date from the file path.
  if not doc.date then
    doc.date = match_date_in_file_path(relative_path_string)
  end

  -- Set relative_filepath on doc.
  -- Remove any leading slash so it is truly relative (not root relative).
  doc.relative_filepath = relative_path_string:gsub("^/", "")

  return doc
end
exports.load_doc = load_doc

local function docs(base_path_string)
  -- Walk directory, creating doc objects from files.
  -- Returns a coroutine iterator function good for each doc table.
  local function load_path_as_doc(path_string)
    -- Remove the base path string to get the relative file path.
    local relative_path_string = path_string:sub(#base_path_string + 1)
    return load_doc(base_path_string, relative_path_string)
  end

  local paths_table = list_file_paths(base_path_string)

  return eduction(map(load_path_as_doc), ipairs(paths_table))
end
exports.docs = docs

local function build(out_path_string, iter, ...)
  -- Remove old build directory recursively.
  if location_exists(out_path_string) then
    assert(remove_recursive(out_path_string))
  end

  local function write_and_tally(number_of_files, doc)
    -- Create new file path from relative path and out path.
    local file_path = path.join(out_path_string, doc.relative_filepath)
    assert(write_entire_file_deep(file_path, doc.contents or ""))
    return number_of_files + 1
  end

  -- Consume doc reducible. Return a tally representing number
  -- of files written.
  return reduce(write_and_tally, 0, iter, ...)
end
exports.build = build

return exports
