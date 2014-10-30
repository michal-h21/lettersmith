--[[
A convention-over-configuration setup for blogging.
Automatically sets up the configuration that 80% of blogs likely want.

Includes:

- Markdown support
- Drafts support
- Pretty date-based permalinks for posts
- Pretty title-based permalinks for pages
- Automatic post pagination
- Automatic post RSS feed

Posts: any markdown file in the root of the build folder is treated as a blog
post. Blog posts will automatically get pretty `year/month/day/post-title`
permalinks, so a blog post called "10 great Lettersmith features" would end up
at `2014/10/30/10-great-lettersmith-features/`.

Pages: any markdown files in the `pages/` folder will automatically get
`page-title/` pretty permalinks. So a page called "Example Page" would end up
`example-page/`.

RSS feeds: an RSS feed is automatically generated for blog posts at `feed/`.

Template metadata: anything you add to the `options` table will be available
within your templates.
]]--

local use_markdown = require("lettersmith_markdown")
local use_drafts = require("lettersmith_drafts")
local use_meta = require("lettersmith_meta")
local use_permalinks = require("lettersmith_permalinks").use
local use_collections = require("lettersmith_collections").use
local use_rss = require("lettersmith_rss").use

local exports = {}

local function use(doc_stream, options)
  local site_title = options.site_title
  local site_description = options.site_description
  local site_url = options.site_url
  local n_per_page = options.per_page or 10

  doc_stream = use_drafts(doc_stream)

  -- Mix options object into doc meta.
  doc_stream = use_meta(doc_stream, options)

  -- Parse markdown
  doc_stream = use_markdown(doc_stream)

  -- Configure pretty blog permalinks for all html files in root directory.
  -- So `post 1.html` becomes `2014/10/26/post-title/`.
  doc_stream = use_permalinks(doc_stream, "*.html", ":yyyy/:mm/:dd/:slug/")

  -- A query that we can use to grab all of the blog posts.
  local post_path_query_string = "????/??/??/*/index.html"

  -- Collect all posts in "posts" collection
  doc_stream = use_collections(doc_stream, "posts", post_path_query_string)

  -- @TODO
  -- doc_stream = use_paging(doc_stream, 
  --   post_path_query_string, n_per_page, "page/:num/index.html")

  -- Configure RSS for posts.
  doc_stream = use_rss(doc_stream, {
    matching = post_path_query_string,
    relative_path = "feed/index.xml",
    site_title = site_title,
    site_description = site_description,
    site_url = site_url
  })

  -- Anything in pages directory is re-written to pretty page URL.
  -- So `pages/about.html` becomes `about/`
  doc_stream = use_permalinks(doc_stream, "pages/*.html", ":slug/")

  -- Collect all pages in "pages" collection
  doc_stream = use_collections(doc_stream, "pages", "*/index.html")

  return doc_stream
end
exports.use = use

return exports