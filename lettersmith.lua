local exports = {}

local transducers = require("lettersmith.transducers")
local reduce = transducers.reduce
local map = transducers.map
local collect = transducers.collect

local lazy = require("lettersmith.lazy")
local transform = lazy.transform
local concat = lazy.concat

local path = require("lettersmith.path")

local compare_by_file_path_date = require("lettersmith.docs_utils").compare_by_file_path_date

local file_utils = require("lettersmith.file_utils")
local location_exists = file_utils.location_exists
local write_entire_file_deep = file_utils.write_entire_file_deep
local read_entire_file = file_utils.read_entire_file
local remove_recursive = file_utils.remove_recursive
local walk_file_paths = file_utils.walk_file_paths

local shallow_copy = require("lettersmith.table_utils").shallow_copy

local headmatter = require("lettersmith.headmatter")

-- Apply a value to a function, returning value.
local function applyTo(v, f)
  return f(v)
end

-- Pipe a value through a series of functions, returning end result.
-- Basically like function composition, but applies value right away.
-- Unlike function composition, goes in LTR order, so the value is first
-- transformed by function `a`, then function `b`, etc.
-- Returns transformed value.
local function pipe(value, a, b, ...)
  return reduce(applyTo, value, ipairs{a, b, ...})
end
exports.pipe = pipe

-- Get a sorted list of all file paths under a given `path_string`.
-- `compare` is a comparison function for `table.sort`.
-- By default, will sort file paths using `compare_by_file_path_date`.
-- Returns a Lua list table of file paths.
local function paths(base_path_string)
  -- Recursively walk through file paths. Collect result in table.
  local file_paths_table = collect(walk_file_paths(base_path_string))
  -- Sort our new table in-place, comparing by date.
  table.sort(file_paths_table, compare_by_file_path_date)
  file_paths_table.base_path = base_path_string
  return file_paths_table
end
exports.paths = paths

-- Load contents of a file as a document table.
-- Returns a new lua document table on success.
-- Throws exception on failure.
local function load_doc(file_path_string)
  -- @fixme get rid of assert in `read_entire_file`
  -- return early with error instead
  local file_string = read_entire_file(file_path_string)

  -- Get YAML meta table and contents from headmatter parser.
  -- We'll use the meta table as the doc object.
  local doc, contents_string = headmatter.parse(file_string)

  -- Since doc is a new table, go ahead and mutate it, setting contents
  -- as field.
  doc.contents = contents_string

  return doc
end
exports.load_doc = load_doc

-- Docs plugin
-- Given a Lettersmith paths table (generated from `lettersmith.paths()`),
-- returns an iterator of docs read from those paths.
local function docs(lettersmith_paths_table)
  local base_path_string = lettersmith_paths_table.base_path

  -- Walk directory, creating doc objects from files.
  -- Returns a coroutine iterator function good for each doc table.
  local function load_doc_from_path(file_path_string)
    local doc = load_doc(file_path_string)

    -- Remove the base path to get the relative file path.
    local relative_path_string = file_path_string:sub(#base_path_string + 1)
    doc.relative_filepath = relative_path_string

    return doc
  end

  return transform(map(load_doc_from_path), ipairs(lettersmith_paths_table))
end
exports.docs = docs

-- Given an `out_path_string` and a list of `doc` iterators, write `contents`
-- of each doc to the `relative_filepath` inside the `out_path_string` directory.
-- Returns a tally for number of files written.
local function build(out_path_string, ...)
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
  return reduce(write_and_tally, 0, concat(...))
end
exports.build = build

-- Transparently require submodules in the lettersmith namespace.
-- Exports of the module lettersmith still have priority.
-- Convenient for client/build scripts, not intended for modules.
local function autoimport()
  local function get_import(t, k)
    t[k] = require("lettersmith." .. k)
    return m
  end

  return setmetatable(shallow_copy(exports), { __index = get_import })
end
exports.autoimport = autoimport

return exports
