local exports = {}

local lettersmith = require("lettersmith")
local query = lettersmith.query

local foldable = require("lettersmith.foldable")
local map = foldable.map
local chunk = foldable.chunk
local concat = foldable.concat

local collections = require("lettersmith.collections")
local link_circularly = collections.link_circularly
local compare_doc_by_date = collections.compare_doc_by_date
local query_and_list_by = collections.query_and_list_by

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

-- Generate fully formed page docs, including relative path.
local function to_page_docs(docs_foldable, template, relative_path_template, n_per_page)
  local pages = to_pages(docs_foldable, n_per_page)

  return map(pages, function (doc)
    -- Generate path from template.
    local relative_path = relative_path_template:gsub(":number", doc.number)
    -- We're mutating doc, but since it was created within the parent closure,
    -- we can get away with it.
    doc.relative_filepath = relative_path
    doc.template = template
    return doc
  end)
end
exports.to_page_docs = to_page_docs

local function use(docs_foldable, options)
  local template = options.template
  local path_query_string = options.matching
  local limit = options.limit or math.huge
  local compare = options.compare or compare_doc_by_date
  local per_page = options.per_page or 20
  local relative_path_template = options.relative_path or "page-:number.html"

  local list =
    query_and_list_by(docs_foldable, path_query_string, compare, limit)

  local pages = to_page_docs(list, template, relative_path_template, per_page)

  return concat(docs_foldable, page_docs)
end
exports.use = use

return exports
