--[[
Lettersmith permalinks

Pretty URLs for your generated files. URL templates are written as strings
with special tokens:

- `:yyyy` the 4-digit year (e.g. 2014)
- `:yy` 2-digit year
- `:mm` 2-digit month
- `:dd` 2-digit day
- `:slug` a pretty version of the `title` field (if present) or the file name.
- `:file_slug` a pretty version of the file name
- `:path` the directory path of the file
- In addition, you may use any string field in the YAML meta by referencing
  it's key name preceded by `:`. So, if you wanted to use the `category` field
  you could write `:category`.

For example, this template:

    :yyyy/:mm/:dd/:slug/

...would result in a permalink like this:

    2014/10/19/example/

Usage:

    local use_permalinks = require('lettersmith.permalinks').use_permalinks
    local lettersmith = require('lettersmith')

    lettersmith.generate("raw", "out", use_permalinks {
      query = "*.html",
      template = ":yyyy/:mm/:slug"
    })
--]]

local exports = {}

local map = require("lettersmith.transducers").map
local transformer = require("lettersmith.lazy").transformer

local table_utils = require("lettersmith.table_utils")
local merge = table_utils.merge
local extend = table_utils.extend

local path = require("lettersmith.path")

local docs = require("lettersmith.docs")
local derive_date = docs.derive_date
local reformat_yyyy_mm_dd = docs.reformat_yyyy_mm_dd
local derive_slug = docs.derive_slug
local to_slug = docs.to_slug

local function is_json_safe(thing)
  local thing_type = type(thing)
  return thing_type == "string"
end

local function build_json_safe_table(t, a2b)
  -- Filter and map values in t, retaining fields that return a value.
  -- Returns new table with values mapped via function `transform`.
  local out = {}
  for k, v in pairs(t) do
    -- Only keep fields which are JSON safe.
    if is_json_safe(k) and is_json_safe(v) then out[k] = a2b(v) end
  end
  return out
end

local function render_doc_path_from_template(doc, url_template)
  local file_path = doc.relative_filepath
  local basename, dir = path.basename(doc.relative_filepath)
  local ext = path.extension(basename)
  local file_title = path.replace_extension(basename, "")

  -- Uses title as slug, but falls back to the file name, sans extension.
  local slug = derive_slug(doc)

  -- This gives you a way to favor file_name.
  local file_slug = to_slug(file_title)

  local yyyy, yy, mm, dd = reformat_yyyy_mm_dd(derive_date(doc), "%Y %y %m %d")
    :match("(%d%d%d%d) (%d%d) (%d%d) (%d%d)")

  -- Generate context object that contains only strings in doc, mapped to slugs
  local doc_context = build_json_safe_table(doc, to_slug)

  -- Merge doc context and extra template vars, favoring template vars.
  local context = extend({
    basename = basename,
    dir = dir,
    file_path = file_path,
    file_slug = file_slug,
    slug = slug,
    ext = ext,
    yyyy = yyyy,
    yy = yy,
    mm = mm,
    dd = dd
  }, doc_context)

  local path_string = url_template:gsub(":([%w_]+)", context)

  -- Add index file to end of path and return.
  return path_string:gsub("/$", "/index" .. ext)
end

-- Remove "index" from end of URL.
local function make_pretty_url(root_url_string, relative_path_string)
  local path_string = path.join(root_url_string, relative_path_string)
  return path_string:gsub("/index%.[^.]*$", "/")
end
exports.make_pretty_url = make_pretty_url

local function render_permalinks(template_string, root_url_string)
  return transformer(map(function(doc)
    local path = render_doc_path_from_template(doc, template_string)
    local url = make_pretty_url(root_url_string or "/", path)
    return merge(doc, {
      relative_filepath = path,
      url = url
    })
  end))
end
exports.render_permalinks = render_permalinks

return exports