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
  return function(doc)
    return doc.relative_filepath:find(pattern)
  end
end
exports.relative_path_matcher = relative_path_matcher

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

local function chop(t, n)
  -- Remove items from end of table `t`, until table length is `n`.
  -- Mutates and returns table.
  while #t > n do table.remove(t, #t) end
  return t
end

local function chop_sorted_buffer(buffer_table, compare, n)
  -- Sort `buffer_table` and remove elements from end until buffer is only
  -- `n` items long.
  -- Mutates and returns buffer.
  table.sort(buffer_table, compare)
  return chop(buffer_table, n)
end

local function harvest(reducible, compare, n)
  -- Skim the cream off the top... given a reducible, a comparison function
  -- and a buffer size, collect the `n` highest values into a table.
  -- This allows you to get a sorted list of items out of a reducible.
  --
  -- `harvest` is useful for very large finite reducibles, where you want
  -- to limit the number of results collected to a set of results that are "more
  -- important" (greater than) by some criteria.

  -- Make sure we have a useful value for `n`.
  -- If you don't provide `n`, `harvest` ends up being equivalent to
  -- collect, then sort.
  n = n or math.huge

  -- Fold a buffer table of items. We mutate this table, but no-one outside
  -- of the function sees it happen.
  local buffer = reducible(function(buffer, item)
    table.insert(buffer, item)
    -- If buffer overflows by 100 items, sort and chop buffer.
    -- In other words, a sort/chop will happen every 100 items over the
    -- threshold... 100 is just an arbitrary batching number to avoid sorting
    -- too often or overflowing buffer... larger than 1, but not too large.
    if #buffer > n + 100 then chop_sorted_buffer(buffer, compare, n) end
    return buffer
  end, {})

  -- Sort and chop buffer one last time on the way out.
  return chop_sorted_buffer(buffer, compare, n)
end
exports.harvest = harvest

return exports