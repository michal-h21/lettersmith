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

  - Simple: no fancy classes, or conventions. Just a small library for
    transforming files with functions.
  - Flexible: everything is a plugin.
  - Fast: build thousands of pages in seconds or less.
  - Embeddable: we're going to put this thing in an Mac app so normal people
    can use it.

  It ships with plugins for blogging, Markdown and Mustache, but can be easily
  configured to build any type of static site.
  ]],
  homepage = "https://github.com/gordonbrander/lettersmith",
  license = "MIT/X11"
}
dependencies = {
  "lua >= 5.1",
  "luafilesystem >= 1.6",
  "lustache >= 1.3",
  "yaml >= 1.1",
  "lua-discount >= 1.2",
  "md5",
  "serpent >= 0.25",
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
    ["lettersmith.rss"] = "lettersmith/rss.lua",
    ["lettersmith.paging"] = "lettersmith/paging.lua",
    ["lettersmith.format_date"] = "lettersmith/format_date.lua",
    ["lettersmith.hash"] = "lettersmith/hash.lua",
    ["lettersmith.serialization"] = "lettersmith/serialization.lua",
    ["lettersmith.debug"] = "lettersmith/debug.lua",

    -- Libraries
    ["lettersmith.transducers"] = "lettersmith/transducers.lua",
    ["lettersmith.lazy"] = "lettersmith/lazy.lua",
    ["lettersmith.docs_utils"] = "lettersmith/docs_utils.lua",
    ["lettersmith.headmatter"] = "lettersmith/headmatter.lua",
    ["lettersmith.path_utils"] = "lettersmith/path_utils.lua",
    ["lettersmith.wildcards"] = "lettersmith/wildcards.lua",
    ["lettersmith.file_utils"] = "lettersmith/file_utils.lua",
    ["lettersmith.table_utils"] = "lettersmith/table_utils.lua",
    ["lettersmith.plugin_utils"] = "lettersmith/plugin_utils.lua"
  }
}
