--[[
Lettersmith Markdown
Renders markdown in contents field.
--]]
local markdown = require("discount")
local map = require("lettersmith.transducers").map
local transformer = require("lettersmith.lazy").transformer
local renderer = require("lettersmith.plugin_utils").renderer

local render_markdown = transformer(map(renderer(markdown)))

return render_markdown