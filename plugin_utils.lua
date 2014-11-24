local exports = {}

local wildcards = require("lettersmith.wildcards")

local lazily = require("lettersmith.lazily")

local xf = require("lettersmith.transducers")
local map = xf.map

local table_utils = require("lettersmith.table_utils")
local merge = table_utils.merge
local defaults = table_utils.defaults

local date = require("date")

local path = require("lettersmith.path")

-- Easily create plugins that only operate on documents matching the given
-- wildcard string:
--
--     plugin = router_plugin(transform_doc, "**.md")
--
-- `default_query` is a wildcard string that allows you to define the docs that
-- will be transformed. The user can override this by defining
-- `{ query = "whatever" }` for the options object.
--
-- Returns a plugin function.
local function plugin(implement, default_options)
  return function(options)
    options = defaults(default_options, options)
    return function(docs)
      return implement(docs, options)
    end
  end
end
exports.plugin = plugin

-- Map only elements passing predicate test. Other elements are left as-is.
--
-- Example:
--
--     xf = branch(add_one, is_number)
--     transduce(xf, step, 0, ipairs{1, "a", 2 "b", 3})
--
local function branch(xform, predicate)
  return function (step)
    local step_xformed = xform(step)
    return function (result, input)
      if predicate(input) then
        -- If input passes test, then step with transformed stepper.
        return step_xformed(result, input)
      else
        -- Otherwise step with original stepper.
        return step(result, input)
      end
    end
  end
end

-- Create a predicate function that will attempt to find a match for
-- `wildcard_string` in doc's file path.
-- Returns predicate function.
local function relative_path_matcher(wildcard_string)
  local pattern = wildcards.parse(wildcard_string)
  return function (doc)
    return doc.relative_filepath:find(pattern)
  end
end

-- Apply transform only to documents that match a particular route.
-- This will apply `xform` to elements that match the route. Elements that don't
-- match will remain in reduction, but will be untouched by `xform`.
--
-- You can use query strings to match documents by wildcard, e.g.
-- `*.md` or `/**.md`.
--
-- Returns an `xform` function.
-- @TODO I may come back to making `a2b` an `xform` rather than a mapping
-- mapping function. This would allow us to compose long logical chains around
-- a single route instead of specifying for each xform that is scoped.
-- Additionally, it lets us keep routing logic out of xforms, only to be applied
-- by plugin or at outermost layer
local function routing(xform, wildcard_string)
  return branch(xform, relative_path_matcher(wildcard_string))
end
exports.routing = routing

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
  local render = doc_renderer(render, rendered_extension)

  return function(query)
    return function(docs)
      return lazily.transform(routing(map(render), query or default_query), docs)
    end
  end
end
exports.renderer_plugin = renderer_plugin

-- Capture a subset of an iterator in a buffer table in order to modify it.
-- Returns a coroutine iterator.
local function capture_and_transform(transform_list, predicate, docs)
  return coroutine.wrap(function ()
    local buffer = {}

    -- Consumes an iterator, capturing each item that passes `predicate` test
    -- in a buffer table. Items that do not pass are yielded immediately.
    for v in docs do
      if predicate(v) then
        table.insert(buffer, v)
      else
        coroutine.yield(v)
      end
    end

    -- Now we've got the buffer. Transform it as necessary with `transform_list`
    -- then loop over the resulting table, yielding each value in turn.
    for i, v in ipairs(transform_list(buffer)) do
      coroutine.yield(v)
    end
  end)
end
exports.capture_and_transform = capture_and_transform

-- Loads a sub-set of the list of documents into a list table, allowing you
-- to alter that list table with `transform_list`.
-- `wildcard_string` looks for a match in the document's file path.
-- `transform_list` receives the table and is expected to return a reducible.
-- The return value of `transform_list` will be folded back into reduction at
-- the very end.
-- Returns a list processing function.
local function query(transform_list, wildcard_string, docs)
  local matches_path = relative_path_matcher(wildcard_string)
  return capture_and_transform(transform_list, matches_path, docs)
end
exports.query = query

local function compare_doc_by_date(a_doc, b_doc)
  -- Compare 2 docs by date, reverse chronological.
  return date(a_doc.date) > date(b_doc.date)
end
exports.compare_doc_by_date = compare_doc_by_date

return exports