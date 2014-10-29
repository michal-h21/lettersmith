-- Given a doc list, will generate an RSS feed file.
-- Can be used as a plugin, or as a helper for a theme plugin.

local query = require("lettersmith").query

local streams = require("streams")
local map = streams.map
local values = streams.values
local skim = streams.skim

local collections = require("lettersmith_collections")
local compare_doc_by_date = collections.compare_doc_by_date

local lustache = require("lustache")

local path = require("path")

local extend = require("table_utils").extend

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
    <pubDate>{{date}}</pubDate>
    {{#author}}
    <author>{{author}}</author>
    {{/author}}
    {{#category}}
    <category>{{category}}</category>
    {{/category}}
  </item>
  {{/items}}
</channel>
</rss>
]]

local function ensure_doc_url(doc, root_url_string)
  -- Make sure a `url` field is present on doc object, using doc
  -- `relative_filepath` and `root_url_string` to create field if it
  -- doesn't exist.
  -- Returns a shallow-copied doc object with `url` field.

  -- Create absolute url from root URL and relative path.
  local url = path.join(root_url_string, doc.relative_filepath)
  local pretty_url = url:gsub("/index%.html$", "/")

  -- Extend doc object into our new object with `url` field. If a `url` field
  -- is already present on the doc object, this will take precidence.
  return extend({ url = pretty_url }, doc)
end
exports.ensure_doc_url = ensure_doc_url

local function render_feed(context_table)
  -- Given table with feed data, render feed string.
  -- Returns rendered string.
  return lustache:render(rss_template_string, context_table)
end
exports.render_feed = render_feed

local function generate_feed_doc(doc_stream, relative_path_string, site_url, site_title, site_description)
  local docs_with_url = map(doc_stream, function(doc)
    return ensure_doc_url(doc, site_url)
  end)

  -- @TODO what is the standard number of items in an RSS feed? Going with 20.
  local top_n_docs = skim(docs_with_url, compare_doc_by_date, 20)

  local contents = render_feed({
    site_url = site_url,
    site_title = site_title,
    site_description = site_description,
    items = top_n_docs
  })

  return {
    -- Set date to most recent document date.
    date = top_n_docs[1].date,
    contents = contents,
    relative_filepath = relative_path_string
  }
end

local function use(doc_stream, options)
  -- Generate RSS feed file and merge into doc stream.
  local relative_path = options.relative_path or "feed.xml"
  local site_url = options.site_url
  local site_title = options.site_title
  local site_description = options.site_description

  local path_query_string = options.matching or "*.html"

  local matching = query(doc_stream, path_query_string)

  local rss = generate_feed_doc(
    matching,
    relative_path,
    site_url,
    site_title,
    site_description
  )

  return streams.merge(doc_stream, values({rss}))
end
exports.use = use

return exports