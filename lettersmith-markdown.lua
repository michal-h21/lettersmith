--[[
Lettersmith Markdown

Renders markdown files (.md, .markdown, .mdown).

Usage:

    local use_markdown = require('lettersmith-markdown')
    local lettersmith = require('lettersmith')

    local docs = lettersmith.docs("raw")
    build(use_markdown(docs), "out")
--]]
local markdown = require('discount')

local lettersmith = require('lettersmith')
local renderer = lettersmith.renderer

return renderer({"%.md", "%.markdown", "%.mdown"}, markdown)
