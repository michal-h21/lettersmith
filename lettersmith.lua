local exports = {}

local streams = require("streams")
local map = streams.map
local map_chosen = streams.map_chosen
local fold = streams.fold

local util = require("util")
local merge = util.merge

local path = require("path")

local path_query = require("query")

local file_utils = require("file-utils")
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

local function route(doc_stream, path_query_string, transform)
  -- Transform documents in stream that match a particular route.
  -- You can use query strings to match documents by wildcard, e.g.
  -- `*.md` or `/**.md`.

  -- Parse query string into pattern.
  local pattern = path_query.parse(path_query_string)

  return map(doc_stream, function (doc)
    -- Skip processing if path does not match query pattern.
    if not doc.relative_filepath:find(pattern) then return doc end
    -- Otherwise transform doc table, replacing it with whatever `transform`
    -- returns.
    return transform(doc)
  end)
end
exports.route = route

local function query(doc_stream, path_query_string)
  -- Filter doc stream to only docs matching `path_query_string`.
  -- `path_query_string` supports wildcard paths.
  local pattern = path_query.parse(path_query_string)

  -- Note the difference between `query` and `route`: `route` will apply a
  -- transformation to each matching doc, but the resulting stream contains all
  -- docs, wheras query actually returns a filtered stream of docs.
  return filter(doc_stream, function (doc)
    return doc.relative_filepath:find(pattern)
  end)
end
exports.query = query

local function render(doc_stream, path_query_string, rendered_extension, render)
  -- A convenience function for writing renderers.
  -- `doc_stream`: the stream of documents to process.
  -- `path_query_string`: a path with optional wildcards.
  -- `rendered_extension`: the extension to use on rendered doc (including .)
  -- `render`: a function to render content.
  -- Returns a new doc stream containing rendered docs and non-rendered docs.

  -- A special route type
  return route(doc_stream, path_query_string, function(doc)
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

local function walk_file_paths_cps(path_string, callback)
  -- Recursively walk through directory at `path_string` calling
  -- `callback` with each file path found.
  for f in children(path_string) do
    local filepath = path.join(path_string, f)

    if is_file(filepath) then
      callback(filepath)
    elseif is_dir(filepath) then
      walk_file_paths_cps(filepath, callback)
    end
  end
end

local function walk_file_paths(path_string)
  -- Given `path_string` -- a path to a directory -- recursively walks through
  -- directory and returns a stream of all file paths.
  -- Returns a stream of file path strings.
  return function(callback)
    walk_file_paths_cps(path_string, callback)
  end
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
  -- Returns a generator function of doc objects.
  -- Warning: generator may only be consumed once! If you need to consume it
  -- more than once, call `docs` again, or use `collect` to load all docs into
  -- an array table.

  local path_stream = walk_file_paths(base_path_string)

  return map(path_stream, function (path_string)
    -- Remove the base path string to get the relative file path.
    local relative_path_string = path_string:sub(#base_path_string + 1)
    return load_doc(base_path_string, relative_path_string)
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
