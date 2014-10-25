--[[
Lettersmith Collections

Add collections of docs, accessible from every doc.

Note that while docs in collection are shallow copies, all docs share a single
reference to the collection. Modify it at your peril.

Usage:

    local use_meta = require('lettersmith-meta')
    local lettersmith = require('lettersmith')
    local docs = lettersmith.docs('raw')

    docs = use_collections(docs, "posts", "blog/")

    build(docs, "out")
--]]
local streams = require('colist')
local map = streams.map
local filter = streams.filter
local collect = streams.collect
local take = streams.take

local date = require("date")

local util = require('util')
local merge = util.merge
local shallow_copy = util.shallow_copy

local mod = {}

function mod.compare_doc_by_date(a_doc, b_doc)
  -- Compare 2 docs by date, reverse chronological.
  return date(a_doc.date) < date(b_doc.date)
end

function mod.query_and_collect(doc_stream, pattern, compare, limit)
  -- Query document stream, returning a list table filtered by `pattern`,
  -- ordered by `compare` and capped by `limit`.
  -- Returns sorted list table of shallow copied doc objects.

  -- Create new filtered stream containing only files that match pattern.
  local sub_path_stream = filter(doc_stream, function (doc)
    return doc.relative_filepath:find(pattern) ~= nil
  end)

  local capped = take(sub_path_stream, limit)

  -- Create shallow copies of doc objects for collection
  local shallow_copies = map(capped, shallow_copy)

  local collection = collect(shallow_copies)

  -- Sort collection in-place
  table.sort(collection, compare)

  return collection
end

function mod.query(doc_stream, pattern, compare, limit)
  -- Just a nice wrapper for query and collect that provides some sensible
  -- argument defaults.
  return mod.query_and_collect(
    doc_stream, pattern, compare or compare_doc_by_date, limit or math.huge)
end

function mod.use(doc_stream, name, pattern, compare, limit)
  local collection = query(doc_stream, pattern, compare, limit)

  return map(doc_stream, function (doc)
    return merge(doc, {
      [name] = collection
    })
  end)
end

return mod