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
local render = lettersmith.render

return function(doc_stream)
  return render(doc_stream, "**.md", '.html', markdown)
end