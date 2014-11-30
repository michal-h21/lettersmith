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
local plugin_utils = require("lettersmith.plugin_utils")
local query = plugin_utils.query
local compare_doc_by_date = plugin_utils.compare_doc_by_date
local harvest = plugin_utils.harvest

local xf = require("lettersmith.transducers")
local transduce = xf.transduce
local comp = xf.comp

local reducers = require("lettersmith.reducers")
local append = reducers.append
local map = reducers.map

local table_utils = require("lettersmith.table_utils")
local extend = table_utils.extend
local shallow_copy = table_utils.shallow_copy
local slice_table = table_utils.slice_table

local exports = {}

local function set_circular_link(prev_t, next_t)
  -- We're mutating both tables, so be wise and pass in tables that are not
  -- owned by anyone else.
  if prev_t then
    prev_t.next = next_t
    next_t.prev = prev_t
    -- Set table index
    next_t.number = prev_t.number + 1
  else
    next_t.number = 1
  end
  return next_t
end

local xform_circular_link = comp(
  xf.reductions(set_circular_link),
  xf.map(shallow_copy)
)

local function link_circularly(t)
  return transduce(xform_circular_link, append, {}, ipairs(t))
end
exports.link_circularly = link_circularly

local function use_collections(name, wildcard_string, compare, n)
  compare = compare or compare_doc_by_date

  return function(docs)
    local docs_table = harvest(query(wildcard_string, docs), compare, n)
    local collection = link_circularly(docs_table)

    local function add_collection_to_doc(doc)
      return extend({ [name] = collection }, doc)
    end

    -- Traverse docs a second time, adding collection to each doc object.
    return map(add_collection_to_doc, docs)
  end
end
exports.use_collections = use_collections

return exports