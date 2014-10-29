--[[
Lettersmith paginate

Don't forget next/prev urls on page docs.
--]]
local lettersmith = require("lettersmith")
local query = lettersmith.query

local streams = require("streams")
local chunk = streams.chunk
local folds = streams.folds

local table_utils = require("table_utils")
local merge = table_utils.merge

local exports = {}

local defaults = {
  -- template = "whatever.html",
  matching = "*.html",
  relative_path = "page/:number/index.html",
  per_page = 10
}

local function maybe_get(t, k)
  if t then
    return t[k]
  else
    return nil
  end
end

local function set_circular_link(doc_1, doc_2)
  -- Set circular link references on document objects. This is pretty
  -- similar to a doubly-linked list.
  -- @todo determine if we actually want to link references or use keys...
  -- perhaps relative_path?
  doc_1.next = doc_2
  doc_2.prev = doc_1
  return doc_1, doc_2
end

local function use(doc_stream, options)
  options = merge(defaults, options)

  local matching = query(doc_stream, options.matching)

  local page_lists = chunk(matching, options.per_page)

  local relative_path_template = options.relative_path

  local page_docs = folds(page_lists, function (prev_doc, list)
    local prev_number = maybe_get(prev_doc, "number") or 0
    local number = prev_number + 1

    local relative_filepath = relative_path_template:gsub(":number", number)

    return {
      relative_filepath = relative_filepath,
      number = number,
      list = list
    }
  end, nil)

  local linked_page_docs = colist(page_docs, link_docs_circular)

  return linked_page_docs
end
exports.use = use

return exports