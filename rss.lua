-- Given a doc list, will generate an RSS feed file.
-- Can be used as a plugin, or as a helper for a theme plugin.

local plugin_utils = require("lettersmith.plugin_utils")
local query = plugin_utils.query
local compare_doc_by_date = plugin_utils.compare_doc_by_date
local harvest = plugin_utils.harvest

local xf = require("lettersmith.transducers")
local transduce = xf.transduce

local reducers = require("lettersmith.reducers")
local append = reducers.append
local from_table = reducers.from_table
local concat = reducers.concat

local lustache = require("lustache")

local path = require("lettersmith.path")

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

local function generate_feed_doc(docs, relative_path_string, site_url, site_title, site_description)
  local function to_rss_item(doc)
    return to_rss_item_from_doc(doc, site_url)
  end

  -- Harvest most recent 20 docs.
  local docs_table = harvest(docs, compare_doc_by_date, 20)
  -- Map table of docs to table of rss items using transducers.
  local items = transduce(xf.map(to_rss_item), append, {}, ipairs(docs_table))

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

  return {
    -- Set date of feed to most recent document date.
    date = feed_date,
    contents = contents,
    relative_filepath = relative_path_string
  }
end
exports.generate_feed_doc = generate_feed_doc

local function use_rss(wildcard_string, file_path_string, site_url, site_title, site_description)
  return function(docs)
    local feed_doc = generate_feed_doc(
      query(wildcard_string, docs),
      file_path_string,
      site_url,
      site_title,
      site_description
    )

    return concat(docs, from_table({ feed_doc }))
  end
end
exports.use_rss = use_rss

return exports