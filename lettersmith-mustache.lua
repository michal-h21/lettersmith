local lustache = require('lustache')

local listable = require('listable')
local merge = listable.merge
local map = listable.map

local lettersmith = require('lettersmith')
local read_file_to_end = lettersmith.read_file_to_end
local join_paths = lettersmith.join_paths

local exports = {}

function render_docs(docs, template_path)
  -- Render docs through mustache template defined in headmatter `template`
  -- field. Returns new docs list.
  return map(docs, function (doc)
    -- Pass on docs that don't have template field.
    if not doc.template then return doc end

    local template = read_file_to_end(join_paths(template_path, doc.template))
    local rendered = lustache:render(template, doc)
    -- Create shallow-copy rendered doc, overwriting doc's contents with
    -- rendered contents.
    return merge(doc, { contents = rendered })
  end)
end
exports.render_docs = render_docs

return exports