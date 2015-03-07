-- Given a doc list, will generate an RSS feed file.
-- Can be used as a plugin, or as a helper for a theme plugin.

local query = require("lettersmith").query

local foldable = require("foldable")
local map = foldable.map
local harvest = foldable.harvest
local concat = foldable.concat
local collect = foldable.collect

local collections = require("lettersmith_collections")
local compare_doc_by_date = collections.compare_doc_by_date

local lustache = require("lustache")

local path = require("path")

local table_utils = require("table_utils")
local extend = table_utils.extend

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

local function generate_feed_doc(docs_foldable, relative_path_string, site_url, site_title, site_description)
  -- @TODO what is the standard number of items in an RSS feed? Going with 20.
  local top_n_docs = harvest(docs_foldable, compare_doc_by_date, 20)

  local items_foldable = map(top_n_docs, function(doc)
    return to_rss_item_from_doc(doc, site_url)
  end)

  local items = collect(items_foldable)

  local contents = render_feed({
    site_url = site_url,
    site_title = site_title,
    site_description = site_description,
    items = items
  })

  return {
    -- Set date of feed to most recent document date.
    date = top_n_docs[1].date,
    contents = contents,
    relative_filepath = relative_path_string
  }
end
exports.generate_feed_doc = generate_feed_doc

local function use(docs_foldable, options)
  -- Generate RSS feed file and merge into doc stream.
  local relative_path = options.relative_path or "feed.xml"
  local site_url = options.site_url
  local site_title = options.site_title
  local site_description = options.site_description

  local path_query_string = options.matching or "*.html"

  local matching = query(docs_foldable, path_query_string)

  local rss = generate_feed_doc(
    matching,
    relative_path,
    site_url,
    site_title,
    site_description
  )

  return concat(docs_foldable, {rss})
end
exports.use = use

return exports