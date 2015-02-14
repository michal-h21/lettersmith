local exports = {}

local foldable = require("lettersmith.foldable")
local map = foldable.map
local fold = foldable.fold
local filter = foldable.filter

local table_utils = require("lettersmith.table_utils")
local merge = table_utils.merge

local path = require("lettersmith.path")

local wildcards = require("lettersmith.wildcards")

local file_utils = require("lettersmith.file_utils")
local children = file_utils.children
local is_file = file_utils.is_file
local is_dir = file_utils.is_dir
local location_exists = file_utils.location_exists
local write_entire_file_deep = file_utils.write_entire_file_deep
local read_entire_file = file_utils.read_entire_file
local remove_recursive = file_utils.remove_recursive

local lfs = require("lfs")

local date = require("date")

local headmatter = require("lettersmith.headmatter")

local function route(docs_foldable, path_query_string, transform)
  -- Transform documents in foldable that match a particular route.
  -- You can use query strings to match documents by wildcard, e.g.
  -- `*.md` or `/**.md`.

  -- Parse query string into pattern.
  local pattern = wildcards.parse(path_query_string)

  -- @todo I'm pretty sure I can better express my weird map/filter situations
  -- with a `folds` function. The idea is that a passing value returns
  -- transformed seed, whereas a non-passing value simply returns seed.
  return map(docs_foldable, function (doc)
    -- Skip processing if path does not match query pattern.
    if not doc.relative_filepath:find(pattern) then return doc end
    -- Otherwise transform doc table, replacing it with whatever `transform`
    -- returns.
    return transform(doc)
  end)
end
exports.route = route

local function query(docs_foldable, path_query_string)
  -- Filter docs matching `path_query_string`.
  -- `path_query_string` supports wildcard paths.
  local pattern = wildcards.parse(path_query_string)

  -- Note the difference between `query` and `route`: `route` will apply a
  -- transformation to each matching doc, but the resulting foldable contains
  -- all docs, wheras query actually returns a filtered foldable of docs.
  return filter(docs_foldable, function (doc)
    return doc.relative_filepath:find(pattern)
  end)
end
exports.query = query

local function render(docs_foldable, path_query_string, rendered_extension, render)
  -- A convenience function for writing renderers.
  -- `docs_foldable`: the foldable of documents to process.
  -- `path_query_string`: a path with optional wildcards.
  -- `rendered_extension`: the extension to use on rendered doc (including .)
  -- `render`: a function to render content.
  -- Returns a new foldable containing rendered docs and non-rendered docs.

  -- A special route type
  return route(docs_foldable, path_query_string, function(doc)
    -- Render contents
    local rendered = render(doc.contents)

    -- Replace file extension
    local relative_filepath = path.replace_extension(
      doc.relative_filepath,
      rendered_extension
    )

    -- Return new shallow-copied doc with rendered contents
    return merge(doc, {
      contents = rendered,
      relative_filepath = relative_filepath
    })
  end)
end
exports.render = render

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
-- directory and returns a foldable of all file paths.
-- Returns a foldable of file path strings.
function walk_file_paths(path_string)
  return foldable.from_cps(walk_file_paths_cps, path_string)
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
  local date_string = doc.date or lfs.attributes(path_string, "modification")
  doc.date = date(date_string):fmt("${iso}")

  -- Set relative_filepath on doc.
  -- Remove any leading slash so it is truly relative (not root relative).
  doc.relative_filepath = relative_path_string:gsub("^/", "")

  return doc
end
exports.load_doc = load_doc

local function docs(base_path_string)
  -- Walk directory, creating doc objects from files.
  -- Returns a generator function of doc objects.
  -- Warning: generator may only be consumed once! If you need to consume it
  -- more than once, call `docs` again, or use `collect` to load all docs into
  -- an array table.

  local path_foldable = walk_file_paths(base_path_string)

  return map(path_foldable, function (path_string)
    -- Remove the base path string to get the relative file path.
    local relative_path_string = path_string:sub(#base_path_string + 1)
    return load_doc(base_path_string, relative_path_string)
  end)
end
exports.docs = docs

local function build(docs_foldable, path_string)
  if location_exists(path_string) then assert(remove_recursive(path_string)) end

  local number_of_files = fold(docs_foldable, function (number_of_files, doc)
    local filepath = path.join(path_string, doc.relative_filepath)
    assert(write_entire_file_deep(filepath, doc.contents or ""))
    return number_of_files + 1
  end, 1)

  return true, number_of_files
end
exports.build = build

return exports
