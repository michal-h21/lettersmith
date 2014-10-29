--[[
Lettersmith Meta

Add metadata to every doc object. This is useful for things like site meta.

Usage:

    local use_meta = require('lettersmith.meta')
    local lettersmith = require('lettersmith')
    local docs = lettersmith.docs('raw')

    local site_meta = {
      site_title = "My Website",
      site_url = "http://example.com"
    }

    build(use_meta(docs, site_meta), "out")
--]]
local streams = require("streams")
local map_stream = streams.map

local table_utils = require("table_utils")
local merge = table_utils.merge

return function (doc_stream, meta)
  -- Add metadata to all documents.
  -- Returns new list of documents with metadata mixed in.
  -- Fields from document take precidence.
  return map_stream(doc_stream, function (doc)
    return merge(meta, doc)
  end)
end