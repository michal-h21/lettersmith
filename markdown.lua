--[[
Lettersmith Markdown
Renders markdown in contents field.
--]]
local markdown = require('discount')

local transducers = require('lettersmith.transducers')
local map = transducers.map

local table_utils = require("lettersmith.table_utils")
local merge = table_utils.merge

local render_markdown = map(function (doc)
  local contents = markdown(doc.contents)
  return merge(doc, { contents = contents })
end)

return render_markdown