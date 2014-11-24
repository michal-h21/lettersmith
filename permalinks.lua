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

local plugin_utils = require("lettersmith.plugin_utils")
local routing = plugin_utils.routing

local xf = require("lettersmith.transducers")
local lazily = require("lettersmith.lazily")

local table_utils = require("lettersmith.table_utils")
local merge = table_utils.merge
local extend = table_utils.extend

local path = require("lettersmith.path")

local date = require("date")

local function trim_string(str)
  return str:gsub("^%s+", ""):gsub("%s+$", "")
end

local function to_slug(str)
  -- Trim string, remove characters that are not numbers, letters or _ and -.
  -- Replace spaces with dashes.
  -- For example, `to_slug("   hEY. there! ")` returns `hey-there`.
  return trim_string(str):gsub("[^%w%s-_]", ""):gsub("%s", "-"):lower()
end
exports.to_slug = to_slug

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
  local basename, dir_path = path.basename(doc.relative_filepath)
  local extension = path.extension(basename)
  local filename = path.replace_extension(basename, "")

  -- Uses title as slug, but falls back to the filename.
  -- @TODO it would probably be better to slugify all the string meta
  -- rather than treating title as a "magic" field. However, this might not
  -- be worth the complication, since this does exactly what you want 80% of
  -- the time.
  local slug = to_slug(doc.title or filename)

  -- This gives you a way to favor filename.
  local file_slug = to_slug(filename)

  -- Parse date and capture granular year, month and day values.
  local doc_date = date(doc.date)
  local yyyy, yy, mm, dd = doc_date
    :fmt("%Y %y %m %d"):match("(%d%d%d%d) (%d%d) (%d%d) (%d%d)")

  -- Generate context object that contains only strings in doc, mapped to slugs
  local doc_context = build_json_safe_table(doc, to_slug)

  -- Merge doc context and extra template vars, favoring template vars.
  local context = extend({
    file_slug = file_slug,
    slug = slug,
    dir_path = dir_path,
    yyyy = yyyy,
    yy = yy,
    mm = mm,
    dd = dd
  }, doc_context)

  local path_string = url_template:gsub(":([%w_]+)", context)

  -- Add index file to end of path and return.
  return path_string:gsub("/$", "/index" .. extension)
end

-- Remove "index" from end of URL.
local function make_pretty_url(root_url_string, relative_path_string)
  local path_string = path.join(root_url_string, relative_path_string)
  return path_string:gsub("/index%.[^.]*$", "/")
end
exports.make_pretty_url = make_pretty_url

local function xform_permalinks(template, root_url)
  return xf.map(function(doc)
    local path = render_doc_path_from_template(doc, template)
    local url = make_pretty_url(root_url or "/", path)
    return merge(doc, {
      relative_filepath = path,
      url = url
    })
  end)
end
exports.xform_permalinks = xform_permalinks

local function use_permalinks(wildcard_string, template_string)
  return function(docs)
    -- Write pretty permalinks for
    local xform = xform_permalinks(template_string)
    return lazily.transform(routing(xform, wildcard_string), docs)    
  end
end
exports.use_permalinks = use_permalinks

return exports