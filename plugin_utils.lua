local exports = {}

local wildcards = require("lettersmith.wildcards")

local trandsucers = require("trandsucers")
local reduce = trandsucers.reduce
local filter = trandsucers.filter

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

-- Create a filtering `xform` function that will keep only docs who's path
-- matches a wildcard path string.
local function query(wildcard_string)
  local pattern = wildcards.parse(wildcard_string)
  return filter(function(doc)
    return doc.relative_filepath:find(pattern)
  end)
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

local function harvest(compare, n, iter, ...)
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

  local function step_buffer(buffer, item)
    table.insert(buffer, item)
    -- If buffer overflows by 100 items, sort and chop buffer.
    -- In other words, a sort/chop will happen every 100 items over the
    -- threshold... 100 is just an arbitrary batching number to avoid sorting
    -- too often or overflowing buffer... larger than 1, but not too large.
    if #buffer > n + 100 then chop_sorted_buffer(buffer, compare, n) end
    return buffer
  end

  -- Fold a buffer table of items. We mutate this table, but no-one outside
  -- of the function sees it happen.
  local buffer = reduce(step_buffer, {}, iter, ...)

  -- Sort and chop buffer one last time on the way out.
  return chop_sorted_buffer(buffer, compare, n)
end
exports.harvest = harvest

return exports