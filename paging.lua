--[[
Lettersmith Paging

Creates a list of doc pages from an iterator of docs.
--]]
local transducers = require("lettersmith.transducers")
local comp = transducers.comp
local map = transducers.map
local reductions = transducers.reductions

local lazy = require("lettersmith.lazy")
local partition = lazy.partition
local transform = lazy.transform

local table_utils = require("lettersmith.table_utils")
local extend = table_utils.extend

-- Set page number on doc table.
local function set_number(prev_t, curr_t)
  if prev_t then
    return extend({ page_number = prev_t.page_number + 1 }, curr_t)
  else
    return extend({ page_number = 1 }, curr_t)
  end
end

local function expand_list_to_doc(list)
  return {
    list = list,
    contents = ""
  }
end

-- Compose `xform` function. Note that `xform` functions compose in
-- reverse (LTR).
local numbered_list_docs = comp(
  map(expand_list_to_doc),
  reductions(set_number)
)

-- Create an iterator of pages from an iterator of docs.
-- Splits docs into pages. Each page is a `doc` with a field called `list`
-- that contains docs for page.
-- `file_path_template` will replace the token `:n` with the page number.
-- Example: `page/:n/index.html`.
-- `per_page` defines how many docs show up in `list` table
-- Returns a coroutine iterator of pages
local function paging(file_path_template, per_page)
  local xform = comp(
    numbered_list_docs,
    map(function(doc)
      local rendered_file_path = file_path_template:gsub(":n", doc.page_number)
      return extend({ relative_filepath = rendered_file_path }, doc)
    end)
  )

  return function(iter, ...)
    -- Partition iterator and then transform resulting iterator using
    -- our composed `xform`.
    return transform(xform, partition(per_page or 10, iter, ...))
  end
end

return paging
