-- http://www.luarocks.org/en/Creating_a_rock
package = "Lettersmith"
version = "scm-1"
source = {
   url = "git://github.com/gordonbrander/lettersmith"
}
description = {
  summary = "A simple, flexible static site generator based on plugins",
  detailed = [[
  Lettersmith is a static site generator. It's goals are:

  - Simple: no fancy classes, no silly conventions. Just a minimal library for
    transforming files with functions.
  - Flexible: everything is a plugin.
  - Fast: build thousands of pages in seconds or less.
  - Embeddable: we're going to put this thing in an Mac app so normal people
    can use it.

  It ships with plugins for blogging, Markdown and Mustache, but can be easily
  extended and configured to build any type of static site.
  ]],
  homepage = "https://github.com/gordonbrander/lettersmith",
  license = "MIT/X11"
}
dependencies = {
  "lua ~> 5.1",
  "luafilesystem ~> 1.6.2",
  "lustache ~> 1.3",
  "yaml ~> 1.1.1",
  "lua-discount ~> 1.2.10.1",
  "date ~> 2.1.1"
}
build = {
  type = "builtin",
  modules = {
    ["lettersmith"] = "lettersmith.lua",

    -- Plugins
    ["lettersmith.mustache"] = "lettersmith/mustache.lua",
    ["lettersmith.permalinks"] = "lettersmith/permalinks.lua",
    ["lettersmith.drafts"] = "lettersmith/drafts.lua",
    ["lettersmith.markdown"] = "lettersmith/markdown.lua",
    ["lettersmith.meta"] = "lettersmith/meta.lua",
    ["lettersmith.blogging"] = "lettersmith/blogging.lua",
    ["lettersmith.collections"] = "lettersmith/collections.lua",
    ["lettersmith.paging"] = "lettersmith/paging.lua",
    ["lettersmith.rss"] = "lettersmith/rss.lua",

    -- Libraries
    ["lettersmith.foldable"] = "lettersmith/foldable.lua",
    ["lettersmith.headmatter"] = "lettersmith/headmatter.lua",
    ["lettersmith.path"] = "lettersmith/path.lua",
    ["lettersmith.file_utils"] = "lettersmith/file_utils.lua",
    ["lettersmith.table_utils"] = "lettersmith/table_utils.lua",
    ["lettersmith.wildcards"] = "lettersmith/wildcards.lua",
  }
}
