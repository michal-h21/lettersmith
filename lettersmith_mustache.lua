--[[
Lettersmith Mustache

Template your docs with mustache.

Usage:

    local use_mustache = require('lettersmith.mustache')
    local lettersmith = require('lettersmith')
    local docs = lettersmith.docs("raw")

    build(use_mustache(docs, "templates"), "out")

Lettersmith `mustache` takes 2 arguments: the docs list and a relative path
to the templates directory.

The function will only template files that have a `template` field in their
headmatter. If the file name provided in the `template` field is invalid,
an error will be thrown.

Note that after you've templated your docs, the `contents` field will contain
all of the HTML, including the template. If you want to keep the raw contents
around, you can copy the docs list, or simply copy the contents field to
another field before templating.
--]]

local lustache = require('lustache')

local streams = require("streams")
local map = streams.map

local table_utils = require("table_utils")
local merge = table_utils.merge

local file_utils = require("file_utils")
local read_entire_file = file_utils.read_entire_file

local path = require('path')

return function (docs, template_path)
  -- Render docs through mustache template defined in headmatter `template`
  -- field. Returns new docs list.
  return map(docs, function (doc)
    -- Pass on docs that don't have template field.
    if not doc.template then return doc end

    local template = read_entire_file(path.join(template_path, doc.template))
    local rendered = lustache:render(template, doc)
    -- Create shallow-copy rendered doc, overwriting doc's contents with
    -- rendered contents.
    return merge(doc, { contents = rendered })
  end)
end