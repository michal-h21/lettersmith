--[[
Lettersmith Markdown

Renders markdown files (.md, .markdown, .mdown).

Usage:

    local use_markdown = require('lettersmith.markdown').use_markdown
    local lettersmith = require('lettersmith')

    lettersmith.generate("raw", "out", use_markdown{ query = "**.txt" })
--]]
local exports = {}

local markdown = require('discount')

local plugin_utils = require('plugin_utils')
local renderer_plugin = plugin_utils.renderer_plugin

exports.use_markdown = renderer_plugin(markdown, "**.md", ".html")

return exports