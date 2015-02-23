local exports = {}

local wildcards = require("lettersmith.wildcards")

local trandsucers = require("lettersmith.transducers")
local reduce = trandsucers.reduce
local filter = trandsucers.filter

local table_utils = require("lettersmith.table_utils")
local merge = table_utils.merge

local date = require("date")

local path = require("lettersmith.path")

-- Create a filtering `xform` function that will keep only docs who's path
-- matches a wildcard path string.
local function query(wildcard_string)
  local pattern = wildcards.parse(wildcard_string)
  return filter(function(doc)
    return doc.relative_filepath:find(pattern)
  end)
end
exports.query = query

local function match_date_in_file_path(file_path_string)
  local basename = path.basename(file_path_string)
  return basename:match("^(%d%d%d%d-%d%d-%d%d)")
end
exports.match_date_in_file_path = match_date_in_file_path

-- Parses a date from filenames that start with the format:
--
--     YEAR-MONTH-DAY
--
-- Where YEAR is a four-digit number, MONTH and DAY are both two-digit numbers.
--
-- Returns a date object from `date()` by parsing an iso date from the file
-- name. If we don't succeed at parsing a date, we return a Unix Epoch date.
local function parse_date_from_file_path(file_path_string)
  if match_date_in_file_path(file_path_string) then
    return date(date_string)
  else
    return date.epoch()
  end
end
exports.parse_date_from_file_path = parse_date_from_file_path

-- Compare 2 file name strings by parsing out a date from the beginning of
-- the file name.
local function compare_by_file_path_date(a, b)
  return parse_date_from_file_path(a) > parse_date_from_file_path(b)
end
exports.compare_by_file_path_date = compare_by_file_path_date

return exports