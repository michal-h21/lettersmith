local exports = {}

local wildcards = require("lettersmith.wildcards")

local reducers = require("lettersmith.reducers")
local map = reducers.map
local filter = reducers.filter

local table_utils = require("lettersmith.table_utils")
local merge = table_utils.merge

local date = require("date")

local path = require("lettersmith.path")

-- Create a predicate function that will attempt to find a match for
-- `wildcard_string` in doc's file path.
-- Returns predicate function.
local function relative_path_matcher(wildcard_string)
  local pattern = wildcards.parse(wildcard_string)
  return function (doc)
    return doc.relative_filepath:find(pattern)
  end
end
exports.relative_path_matcher

-- Apply transform only to documents that match a particular route.
-- This will trasform each doc that matches the route. Docs that don't
-- match will be untouched.
--
-- You can use query strings to match documents by wildcard, e.g.
-- `*.md` or `/**.md`.
--
-- Returns reducible function.
local function route(wildcard_string, a2b, docs)
  local matches_relative_path = relative_path_matcher(wildcard_string)
  return map(function(doc)
    -- Skip docs that don't match path.
    if not matches_relative_path(doc) then return doc end

    -- Transform docs that do match path.
    return a2b(doc)
  end, docs)
end
exports.route = route

local function doc_renderer(render, rendered_extension)
  return function (doc)
    -- Render contents
    local rendered = render(doc.contents)

    -- Replace file extension
    local relative_filepath = path.replace_extension(
      doc.relative_filepath,
      rendered_extension
    )

    -- Return new shallow-copied doc with rendered contents
    return merge(doc, {
      contents = rendered,
      relative_filepath = relative_filepath
    })
  end
end
exports.doc_renderer = doc_renderer

-- Easily create a renderer plugin with a rendering function, default render
-- query and a rendered file extension:
--
--     plugin = renderer_plugin(markdown, "**.md", ".html")
--
-- `default_query` is a wildcard string that allows you to define the docs that
-- will be rendered. The user can override this by defining
-- `{ query = "whatever" }` for the options object.
--
-- Returns a plugin function.
local function renderer_plugin(render, default_query, rendered_extension)
  local render_doc = doc_renderer(render, rendered_extension)

  return function(query)
    return function(docs)
      return route(query or default_query, render_doc, docs)
    end
  end
end
exports.renderer_plugin = renderer_plugin

-- Filter reducible to only docs who's relative path matches `wildcard_string`.
-- Returns new reducible function.
local function query(wildcard_string, docs)
  return filter(relative_path_matcher(wildcard_string), docs)
end
exports.query = query

local function compare_doc_by_date(a_doc, b_doc)
  -- Compare 2 docs by date, reverse chronological.
  return date(a_doc.date) > date(b_doc.date)
end
exports.compare_doc_by_date = compare_doc_by_date

return exports