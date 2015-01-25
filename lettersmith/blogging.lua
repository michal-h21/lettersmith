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

local concat = require("lettersmith.foldable").concat

local use_markdown = require("lettersmith.markdown")
local use_drafts = require("lettersmith.drafts")
local use_meta = require("lettersmith.meta")
local use_permalinks = require("lettersmith.permalinks").use

local collections = require("lettersmith.collections")
local compare_doc_by_date = collections.compare_doc_by_date
local query_and_list_by = collections.query_and_list_by

local to_page_docs = require("lettersmith.paging").to_page_docs
local generate_feed_doc = require("lettersmith.rss").generate_feed_doc

local exports = {}

local function use(docs_foldable, options)
  local site_title = options.site_title
  local site_description = options.site_description
  local site_url = options.site_url
  local n_per_page = options.per_page or 20
  local archive_template = options.archive_template or "archive.html"

  docs_foldable = use_drafts(docs_foldable)

  -- Mix options object into doc meta.
  docs_foldable = use_meta(docs_foldable, options)

  -- Parse markdown
  docs_foldable = use_markdown(docs_foldable)

  -- Configure pretty blog permalinks for all html files in root directory.
  -- So `post 1.html` becomes `2014/10/26/post-title/`.
  docs_foldable = use_permalinks(docs_foldable, "*.html", ":yyyy/:mm/:dd/:slug/")

  -- Anything in pages directory is re-written to pretty page URL.
  -- So `pages/about.html` becomes `about/`
  docs_foldable = use_permalinks(docs_foldable, "pages/*.html", ":slug/")

  -- Query docs for posts. Collect all of those posts into a sorted table.
  -- This allows us to walk the docs list only 2x. Once for each doc and then
  -- once for list consumers like RSS and archive pages.
  local posts_list = query_and_list_by(
    docs_foldable,
    "????/??/??/*/index.html",
    compare_doc_by_date
  )

  local archive_pages = to_page_docs(
    posts_list,
    archive_template,
    "page/:number/index.html",
    n_per_page
  )

  docs_foldable = concat(docs_foldable, archive_pages)

  local rss_doc = generate_feed_doc(
    posts_list,
    "feed/index.xml",
    site_url,
    site_title,
    site_title
  )

  docs_foldable = concat(docs_foldable, {rss_doc})

  return docs_foldable
end
exports.use = use

return exports
