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

local date = require("date")

local util = require('util')
local merge = util.merge
local shallow_copy = util.shallow_copy

local function compare_doc_by_date(a_doc, b_doc)
  -- Compare 2 docs by date, reverse chronological.
  return date(a_doc.date) < date(b_doc.date)
end

return function (doc_stream, name, pattern, compare)
  -- Add metadata to all documents.
  -- Returns new list of documents with metadata mixed in.
  -- Fields from document take precidence.
  local sub_path_stream = filter(doc_stream, function (doc)
    return doc.relative_filepath:find(pattern) ~= nil
  end)

  -- Create shallow copies of doc objects for collection
  local sub_path_copies = map(sub_path_stream, shallow_copy)

  local collection = collect(sub_path_stream)
  -- Sort collection
  table.sort(collection, compare or compare_doc_by_date)

  return map(doc_stream, function (doc)
    return merge(doc, {
      [name] = collection
    })
  end)
end