local markdown = require('discount')

local list = require('colist')
local map = list.map

local util = require('util')
local merge = util.merge

local lettersmith = require('lettersmith')
local contains_any = lettersmith.contains_any

local exports = {}

local ext = {"%.md", "%.markdown", "%.mdown"}

return function (docs)
  -- Render docs through mustache template defined in headmatter `template`
  -- field. Returns new docs list.
  return map(docs, function (doc)
    -- Pass on docs that don't have markdown extension.
    if not contains_any(doc.relative_filepath, ext) then return doc end

    local rendered = markdown(doc.contents)

    -- Create shallow-copy rendered doc, overwriting doc's contents with
    -- rendered contents.
    return merge(doc, { contents = rendered })
  end)
end