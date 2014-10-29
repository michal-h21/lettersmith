--[[
Lettersmith Collections

Add collections of docs, accessible from every doc.

Note that while docs in collection are shallow copies, all docs share a single
reference to the collection. Modify it at your peril.

Usage:

    local use_collections = require('lettersmith.collections')
    local lettersmith = require('lettersmith')
    local docs = lettersmith.docs('raw')

    docs = use_collections(docs, "posts", "blog/")

    build(docs, "out")
--]]
local lettersmith = require("lettersmith")
local query_docs = lettersmith.query

local streams = require("streams")
local map_stream = streams.map
local skim_stream = streams.skim

local date = require("date")

local table_utils = require("table_utils")
local merge = table_utils.merge
local shallow_copy = table_utils.shallow_copy
local map_table = table_utils.map

local exports = {}

local function compare_doc_by_date(a_doc, b_doc)
  -- Compare 2 docs by date, reverse chronological.
  return date(a_doc.date) < date(b_doc.date)
end
exports.compare_doc_by_date = compare_doc_by_date

local function list_in_order(doc_stream, path_query_string, compare, n)
  -- Query document stream, returning a list table filtered by path query
  -- string, ordered by `compare` and capped by `n`.
  -- Returns sorted list table of shallow copied doc objects.

  -- Create new filtered stream containing only files that match pattern.
  local matches = query_docs(doc_stream, path_query_string)

  local top_n = skim_stream(matches, compare, n)

  -- Create shallow copies of doc objects for collection.
  return map_table(top_n, shallow_copy)
end
exports.list_in_order = list_in_order

local function use(doc_stream, name, path_query_string, compare, n)
  -- Default to comparing files by date.
  compare = compare or compare_doc_by_date

  -- Create collection of shallow copies
  local collection = list_in_order(doc_stream, path_query_string, compare, n)

  return map_stream(doc_stream, function (doc)
    return merge(doc, {
      [name] = collection
    })
  end)
end
exports.use = use

return exports