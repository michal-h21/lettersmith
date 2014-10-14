--[[
Lettersmith Meta

Add metadata to every doc object. This is useful for things like site meta.

Usage:

    local use_meta = require('lettersmith-meta')
    local lettersmith = require('lettersmith')
    local docs = lettersmith.docs('raw')

    local site_meta = {
      site_title = "My Website",
      site_url = "http://example.com"
    }

    build(use_meta(docs, site_meta), "out")
--]]
local list = require('colist')
local map = list.map

local util = require('util')
local merge = util.merge

return function (docs, meta)
  -- Add metadata to all documents.
  -- Returns new list of documents with metadata mixed in.
  -- Fields from document take precidence.
  return map(docs, function (doc)
    return merge(meta, doc)
  end)
end