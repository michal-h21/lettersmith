-- Given a doc list, will generate an RSS feed file.
-- Can be used as a plugin, or as a helper for a theme plugin.

local plugin_utils = require("plugin_utils")
local query = plugin_utils.query
local compare_doc_by_date = plugin_utils.compare_doc_by_date

local xf = require("transducers")
local transduce = xf.transduce
local map = xf.map

local lazily = require("lazily")
local append = lazily.append

local lustache = require("lustache")

local path = require("path")

local table_utils = require("table_utils")
local extend = table_utils.extend
local shallow_copy = table_utils.shallow_copy
local slice_table = table_utils.slice_table

local date = require("date")

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
exports.render_feed = render_feed

local function to_rss_item_from_doc(doc, root_url_string)
  local title = doc.title
  local contents = doc.contents
  local author = doc.author

  local pubdate = date(doc.date):fmt("${rfc1123}")

  -- Create absolute url from root URL and relative path.
  local url = path.join(root_url_string, doc.relative_filepath)
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

local function sort(t, compare)
  t = shallow_copy(t)
  table.sort(t, compare)
  return t
end

local function generate_feed_doc(docs_table, relative_path_string, site_url, site_title, site_description)
  local function to_rss_item(doc)
    return to_rss_item_from_doc(doc, site_url)
  end

  local items = transduce(map(to_rss_item), append, {}, ipairs(docs_table))

  local contents = render_feed({
    site_url = site_url,
    site_title = site_title,
    site_description = site_description,
    items = items
  })

  return {
    -- Set date of feed to most recent document date.
    date = items[1].date,
    contents = contents,
    relative_filepath = relative_path_string
  }
end
exports.generate_feed_doc = generate_feed_doc

local function use_rss(wildcard_string, file_path_string, site_url, site_title, site_description)
  local function append_rss(docs_table)
    docs_table = sort(docs_table, compare_doc_by_date)

    local rss_items = slice_table(docs_table, 1, 20)

    local feed_doc = generate_feed_doc(
      rss_items,
      file_path_string,
      site_url,
      site_title,
      site_description
    )

    table.insert(docs_table, feed_doc)

    return docs_table
  end

  return function(docs)
    return query(append_rss, wildcard_string, docs)
  end
end
exports.use_rss = use_rss

return exports