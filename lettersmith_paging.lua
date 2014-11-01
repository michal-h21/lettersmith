local exports = {}

local lettersmith = require("lettersmith")
local query = lettersmith.query

local foldable = require("foldable")
local map = foldable.map
local chunk = foldable.chunk

local collections = require("lettersmith_collections")
local link_circularly = collections.link_circularly
local compare_doc_by_date = collections.compare_doc_by_date

local function expand_docs_to_page(docs_table)
  -- @todo this should be considered a page doc.
  -- Should we give those a date or contents? Probably not. That would
  -- be pretty pointless.
  return { docs = docs_table }
end

local function to_pages(docs_foldable, n_per_page)
  -- Link docs.
  local linked = link_circularly(docs_foldable)

  -- Chunk into pages
  local chunks = chunk(linked, n_per_page)

  local pages = map(chunks, expand_docs_to_page)

  -- Link pages
  local linked_pages = link_circularly(pages)

  -- Return page chunks.
  return linked_pages
end
exports.to_pages = to_pages

local function use(docs_foldable, options)
  local path_query_string = options.path_query_string
  local limit = options.limit
  local compare = options.compare or compare_doc_by_date
  local per_page = options.per_page or 20
  local relative_path_template = options.template or "page-:number.html"

  local matches = query(docs_foldable, path_query_string)

  local collection = list_collection(matches, compare, limit)

  local pages = to_pages(collection, per_page)

  local page_docs = map(pages, function (doc)
    -- Generate path from template.
    local relative_path = relative_path_template:gsub(":number", doc.number)
    -- We're mutating doc, but since it was created within the parent closure,
    -- we can get away with it.
    doc.relative_filepath = relative_path
    return doc
  end)

  return concat(docs_foldable, pages)
end
exports.use = use

return exports