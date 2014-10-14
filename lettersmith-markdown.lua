local markdown = require('discount')

local lettersmith = require('lettersmith')
local renderer = lettersmith.renderer

return renderer({"%.md", "%.markdown", "%.mdown"}, markdown)
