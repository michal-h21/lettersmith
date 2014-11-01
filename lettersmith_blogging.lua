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
local use_paging = require("lettersmith_paging").use
local use_rss = require("lettersmith_rss").use

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

  -- A query that we can use to grab all of the blog posts.
  local post_path_query_string = "????/??/??/*/index.html"

  -- @TODO we lose a lot of time to re-walking the docs_foldable twice -- once
  -- for paging, once for rss. To speed things up, we could:
  -- create a lower-level paging and RSS function,
  -- query docs ourselves,
  -- harvest (and sort) the query results into a table,
  -- pass harvested table to rss and paging.
  -- I think this should act as a memoization -- we keep the docs in memory we
  -- need to list in memory. We don't even lose anything memory-pressure-wise.
  -- Paging needs to be able to sort everything before chunking anyhow.

  docs_foldable = use_paging(docs_foldable, {
    matching = post_path_query_string,
    per_page = n_per_page,
    template = archive_template,
    relative_path = "page/:number/index.html"
  })

  -- Configure RSS for posts.
  docs_foldable = use_rss(docs_foldable, {
    matching = post_path_query_string,
    relative_path = "feed/index.xml",
    site_title = site_title,
    site_description = site_description,
    site_url = site_url
  })

  -- Anything in pages directory is re-written to pretty page URL.
  -- So `pages/about.html` becomes `about/`
  docs_foldable = use_permalinks(docs_foldable, "pages/*.html", ":slug/")

  return docs_foldable
end
exports.use = use

return exports