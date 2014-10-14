local lustache = require('lustache')

local list = require('colist')
local map = list.map

local util = require('util')
local merge = util.merge

local lettersmith = require('lettersmith')
local read_entire_file = lettersmith.read_entire_file
local join_paths = lettersmith.join_paths

return function (docs, template_path)
  -- Render docs through mustache template defined in headmatter `template`
  -- field. Returns new docs list.
  return map(docs, function (doc)
    -- Pass on docs that don't have template field.
    if not doc.template then return doc end

    local template = read_entire_file(join_paths(template_path, doc.template))
    local rendered = lustache:render(template, doc)
    -- Create shallow-copy rendered doc, overwriting doc's contents with
    -- rendered contents.
    return merge(doc, { contents = rendered })
  end)
end
