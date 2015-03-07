--[[
Handy functions for working with `doc` tables.
]]--

local exports = {}

local date = require("date")
local path = require("lettersmith.path")

-- Returns the title of the doc from headmatter, or the first sentence of
-- the contents.
local function derive_title(doc)
  if doc.title then
    return doc.title
  else
    -- @FIXME this is naive and is not localized.
    -- In future, would be better to be able to generate titles from
    -- contents field. But before we do that, we'll need a clever way to strip
    -- special characters like HTML and markdown. Maybe impossible?
    return "Untitled"
  end
end
exports.derive_title = derive_title

local function trim_string(s)
  return s:gsub("^%s+", ""):gsub("%s+$", "")
end

-- Trim string, remove characters that are not numbers, letters or _ and -.
-- Replace spaces with dashes.
-- For example, `to_slug("   hEY. there! ")` returns `hey-there`.
local function to_slug(s)
  return trim_string(s):gsub("[^%w%s-_]", ""):gsub("%s", "-"):lower()
end
exports.to_slug = to_slug

local function find_slug_in_file_path(file_path_string)
  local file_name = path.replace_extension(path.basename(file_path_string), "")
  -- Remove date if present
  return file_name:gsub("^%d%d%d%d%-%d%d%-%d%d%-?", "", 1)
end

-- Derive a pretty permalink slug from a `doc` table.
-- `derive_slug` will do its best to create something nice.
-- Returns a slug made from title, filename or contents.
local function derive_slug(doc)
  local file_name_slug = find_slug_in_file_path(doc.relative_filepath)

  -- Prefer title if present.
  if doc.title then
    return to_slug(doc.title)
  -- Fall back to slug derived from file name.
  elseif #file_name_slug > 0 then
    -- Make really sure it is slug-friendly.
    return to_slug(file_name_slug)
  else
    -- Otherwise, derive title and slugify it.
    -- @TODO decide if we should limit this.
    return to_slug(derive_title(doc))
  end
end
exports.derive_slug = derive_slug

-- Match a `YYYY-MM-DD` date at the beginning of a string.
-- Returns matched string or `nil`.
local function match_iso_date(string)
  if string then
    return string:match("^%d%d%d%d%-%d%d%-%d%d")
  end
end

-- Matches a date from filenames that have the format:
--
--     YEAR-MONTH-DAY-whatever
--
-- Where YEAR is a four-digit number, MONTH and DAY are both two-digit numbers.
--
-- Returns the matched date string, or `nil`.
local function match_date_in_file_path(file_path_string)
  return match_iso_date(path.basename(file_path_string))
end
exports.match_date_in_file_path = match_date_in_file_path

local epoch_yyyy_mm_dd = date.epoch():fmt("%F")

-- Derive a date string from a `doc` table. Will look at valid date fields in
-- headmatter, file path or fall back to epoch if nothing else.
-- Returns a `YYYY-MM-DD` date string.
local function derive_date(doc)
  local headmatter_date_string = match_iso_date(doc.date)
  local file_path_date_string = match_date_in_file_path(doc.relative_filepath)

  if headmatter_date_string then
    return headmatter_date_string
  elseif file_path_date_string then
    return file_path_date_string
  else
    return epoch_yyyy_mm_dd
  end
end
exports.derive_date = derive_date

-- Get a `YYYY-MM-DD` date string from a file path. Returns a date string if
-- found, or the unix epoch if not.
local function read_date_from_file_path(file_path_string)
  local extracted_date = match_date_in_file_path(file_path_string)
  if extracted_date then
    return extracted_date
  else
    return epoch_yyyy_mm_dd
  end
end
exports.read_date_from_file_path = read_date_from_file_path

-- Compare 2 file name strings by parsing out a date from the beginning of
-- the file name.
local function compare_by_file_path_date(a, b)
  return date(read_date_from_file_path(a)) > date(read_date_from_file_path(b))
end
exports.compare_by_file_path_date = compare_by_file_path_date

return exports
