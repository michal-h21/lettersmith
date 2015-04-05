-- Given a doc list, will generate an RSS feed file.
-- Can be used as a plugin, or as a helper for a theme plugin.

local transducers = require("lettersmith.transducers")
local into = transducers.into
local map = transducers.map

local wrap_in_iter = require("lettersmith.plugin_utils").wrap_in_iter

local lustache = require("lustache")

local path_utils = require("lettersmith.path_utils")

local docs = require("docs_utils")
local derive_date = docs.derive_date
local reformat_yyyy_mm_dd = docs.reformat_yyyy_mm_dd

local exports = {}

-- Note that escaping the description is uneccesary because Mustache escapes
-- by default!
local rss_template_string = [[
<rss version="2.0">
<channel>
  <title>{{site_title}}</title>
  <link>{{{site_url}}}</link>
  <description>{{site_description}}</description>
  <generator>Lettersmith</generator>
  {{#items}}
  <item>
    {{#title}}
    <title>{{title}}</title>
    {{/title}}
    <link>{{{url}}}</link>
    <description>{{contents}}></description>
    <pubDate>{{pubdate}}</pubDate>
    {{#author}}
    <author>{{author}}</author>
    {{/author}}
  </item>
  {{/items}}
</channel>
</rss>
]]

local function render_feed(context_table)
  -- Given table with feed data, render feed string.
  -- Returns rendered string.
  return lustache:render(rss_template_string, context_table)
end

local function to_rss_item_from_doc(doc, root_url_string)
  local title = doc.title
  local contents = doc.contents
  local author = doc.author

  -- Reformat doc date as RFC 1123, per RSS spec
  -- http://tools.ietf.org/html/rfc1123.html
  -- @TODO determine if this is could get tripped up by time zones or something.
  local pubdate =
    reformat_yyyy_mm_dd(derive_date(doc), "%a, %d %b %Y %H:%M:%S GMT")

  -- Create absolute url from root URL and relative path.
  local url = path_utils.join(root_url_string, doc.relative_filepath)
  local pretty_url = url:gsub("/index%.html$", "/")

  -- The RSS template doesn't really change, so no need to get fancy.
  -- Return just the properties we need for the RSS template.
  return {
    title = title,
    url = pretty_url,
    contents = contents,
    pubdate = pubdate,
    author = author
  }
end

local function generate_rss(relative_filepath, site_url, site_title, site_description)
  local function to_rss_item(doc)
    return to_rss_item_from_doc(doc, site_url)
  end

  local take_20_rss_items = comp(take(20), map(to_rss_item))

  return function(iter, ...)
    -- Map table of docs to table of rss items using transducers.
    local items = into(take_20_rss_items, iter, ...)

    local contents = render_feed({
      site_url = site_url,
      site_title = site_title,
      site_description = site_description,
      items = items
    })

    if #items > 0 then
      local feed_date = items[1].date
    else
      local feed_date = date(os.time()):fmt("${rfc1123}")
    end

    return wrap_in_iter({
      -- Set date of feed to most recent document date.
      date = feed_date,
      contents = contents,
      relative_filepath = relative_filepath
    })
  end
end
exports.generate_rss = generate_rss

return exports
