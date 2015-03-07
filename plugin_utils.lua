local exports = {}

local wildcards = require("lettersmith.wildcards")
local filter = require("lettersmith.transducers").filter
local transformer = require("lettersmith.lazy").transformer

local table_utils = require("lettersmith.table_utils")
local merge = table_utils.merge

-- Create a plugin function that will keep only docs who's path
-- matches a wildcard path string.
local function query(wildcard_string)
  return transformer(filter(function(doc)
    return doc.relative_filepath:find(wildcards.parse(wildcard_string))
  end))
end
exports.query = query

-- Render contents through mapping function `a2b`.
-- Returns a rendering function which will transform a `doc` object,
-- returning a new doc object with contents field transformed by `a2b`.
local function renderer(a2b)
  return function(doc)
    return merge(doc, { contents = a2b(doc.contents) })
  end
end
exports.renderer = renderer

-- Wrap value in a coroutine iterator.
local function wrap_in_iter(thing)
  return coroutine.wrap(function ()
    coroutine.yield(thing)
  end)
end
exports.wrap_in_iter = wrap_in_iter

return exports