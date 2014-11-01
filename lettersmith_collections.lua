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
local query = lettersmith.query

local foldable = require("foldable")
local fold = foldable.fold
local map = foldable.map
local folds = foldable.folds
local harvest = foldable.harvest
local collect = foldable.collect

local date = require("date")

local table_utils = require("table_utils")
local merge = table_utils.merge
local shallow_copy = table_utils.shallow_copy

local exports = {}

local function compare_doc_by_date(a_doc, b_doc)
  -- Compare 2 docs by date, reverse chronological.
  return date(a_doc.date) > date(b_doc.date)
end
exports.compare_doc_by_date = compare_doc_by_date

-- Delay each value in a foldable value by one turn.
-- Why? It's useful for producing `folds` where both arguments to the folding
-- function are mutated. Sounds confusing, but it lets you do the mutation
-- before anyone else can see it.
-- As Clojure puts it "if a tree mutates in a forest and no one hears it...".
local function detain(foldable)
  return function(step, seed)
    local v = fold(foldable, function (last, v)
      if (last) then seed = step(seed, last) end
      return v
    end, nil)

    return step(seed, v)
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

-- Turn foldable full of tables into a circular linked list. Note that tables
-- will be shallow copied before this is done, so the originals won't be
-- mutated. We also detain each value, so the circular link mutation is never
-- seen by anyone. Basically this means you can still fold tables "just in time"
-- and they will have both the `prev` and `next` property when you receive them.
local function link_circularly(tables_foldable)
  return detain(folds(map(tables_foldable, shallow_copy), set_circular_link))
end
exports.link_circularly = link_circularly

local function list_collection(docs_foldable, compare, n)
  -- Harvest the top `n` sorted tables.
  local top_n = harvest(docs_foldable, compare, n)

  -- Create circular next/prev references between shallow copies.
  local linked = link_circularly(top_n)

  -- Collect into indexed table
  return collect(linked)
end
exports.list_collection = list_collection

local function use(docs_foldable, name, path_query_string, compare, n)
  -- Default to comparing files by date.
  compare = compare or compare_doc_by_date

  local matches =
    query(docs_foldable, path_query_string, compare, n)

  local collection = list_collection(matches, compare, n)

  return map(docs_foldable, function (doc)
    return merge(doc, {
      [name] = collection
    })
  end)
end
exports.use = use

return exports