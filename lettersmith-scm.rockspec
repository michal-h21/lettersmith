-- http://www.luarocks.org/en/Creating_a_rock
package = "Lettersmith"
version = "0.0-1"
source = {
  url = "git://github.com/gordonbrander/lettersmith"
}
description = {
  summary = "A simple, flexible static site generator based on plugins",
  detailed = [[
  Lettersmith is a simple, flexible static site generator that lets you create
  websites from text files and images.

  Lettersmith provides Markdown support, Mustache templates, metadata support
  and more. It's core concept is that files everything is a plugin. That means
  adding new functionality to Lettersmith is as easy as writing a Lua function!
  ]],
  -- homepage = "http://...", -- We don't have one yet
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
    ["lettersmith.mustache"] = "lettersmith_mustache.lua",
    ["lettersmith.permalinks"] = "lettersmith_permalinks.lua",
    ["lettersmith.drafts"] = "lettersmith_drafts.lua",
    ["lettersmith.markdown"] = "lettersmith_markown.lua",
    ["lettersmith.meta"] = "lettersmith_meta.lua",

    -- Libraries
    ["lettersmith.foldable"] = "foldable.lua",
    ["lettersmith.headmatter"] = "headmatter.lua",
    ["lettersmith.path"] = "lettersmith.path",
    ["lettersmith.file_utils"] = "file_utils.lua",
    ["lettersmith.table_utils"] = "table_utils.lua"
  }
}