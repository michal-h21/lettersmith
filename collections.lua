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

local transduce = require("lettersmith.transducers")
local transduce = transduce.transduce
local comp = transduce.comp
local map = transduce.map
local reductions = transduce.reductions

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
exports.set_circular_link = set_circular_link

local link_tables = comp(
  map(shallow_copy),
  reductions(set_circular_link)
)
exports.link_tables = link_tables

local function collect(iter, ...)
  return into({}, link_tables, iter, ...)
end
exports.collect = collect

return exports