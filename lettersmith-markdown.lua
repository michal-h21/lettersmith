local markdown = require('discount')

local listable = require('listable')
local merge = listable.merge
local map = listable.map

local exports = {}

function contains_any(s, patterns)
  for _, pattern in pairs(patterns) do
    local i = s:find(pattern)
    if i ~= nil then return true end
  end
  return false
end

local ext = {"%.md", "%.markdown", "%.mdown"}

function process(docs)
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
exports.process = process

return exports