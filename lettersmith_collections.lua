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
local plugin_utils = require("plugin_utils")
local query = plugin_utils.query
local compare_doc_by_date = plugin_utils.compare_doc_by_date

local xf = require("transducers")
local transduce = xf.transduce
local map = xf.map
local reductions = xf.reductions
local comp = xf.comp

local lazily = require("lazily")
local append = lazily.append

local table_utils = require("table_utils")
local extend = table_utils.extend
local shallow_copy = table_utils.shallow_copy
local slice_table = table_utils.slice_table

local exports = {}

-- Delay each value in a foldable value by one turn.
-- Why? It's useful for producing `folds` where both arguments to the folding
-- function are mutated. Sounds confusing, but it lets you do the mutation
-- before anyone else can see it.
-- As Clojure puts it "if a tree mutates in a forest and no one hears it...".
local function detain(foldable)
  return function(step, seed)
    local final_v = fold(foldable, function (prev, v)
      if (prev) then seed = step(seed, prev) end
      return v
    end, nil)

    -- Acumulate last left-over value.
    return step(seed, final_v)
  end
end

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
  reductions(set_circular_link),
  map(shallow_copy)
)

-- Turn foldable full of tables into a circular linked list. Note that tables
-- will be shallow copied before this is done, so the originals won't be
-- mutated. We also detain each value, so the circular link mutation is never
-- seen by anyone. Basically this means you can still fold tables "just in time"
-- and they will have both the `prev` and `next` property when you receive them.
local function link_circularly(iter, state, at)
  return transduce(xform_circular_link, append, {}, iter, state, at)
end
exports.link_circularly = link_circularly

local function sort(t, compare)
  local copy = slice_table(t)
  table.sort(copy, compare)
  return copy
end

local function create_collection(t, compare, limit)
  local sorted = sort(t, compare)
  if limit then sorted = slice_table(sorted, 1, limit) end
  return link_circularly(ipairs(sorted))
end

local function use_collections(name, wildcard_string, compare, limit)
  compare = compare or compare_doc_by_date
  local function build_collection(docs_table)
    local collection = create_collection(docs_table, compare, limit)

    local function add_collection_to_doc(doc)
      return extend({ [name] = collection }, doc)
    end

    return transduce(map(add_collection_to_doc), append, {}, ipairs(docs_table))
  end

  return function(docs)
    return query(build_collection, wildcard_string, docs)
  end
end
exports.use_collections = use_collections

return exports