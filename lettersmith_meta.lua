--[[
Lettersmith Meta

Add metadata to every doc object. This is useful for things like site meta.

Usage:

    local use_meta = require('lettersmith.meta').plugin
    local lettersmith = require('lettersmith')

    lettersmith.generate("raw", "out", use_meta{ site_title = "My website" })
--]]
local exports = {}

local lazily = require("lazily")
local transducers = require("transducers")

local table_utils = require("table_utils")
local merge = table_utils.merge

local function map_meta(meta)
  return transducers.map(function (doc)
    return merge(meta, doc)
  end)
end
exports.map_meta = map_meta

local function plugin(meta)
  local xf = map_meta(meta)

  return function (docs)
    return lazily.transform(xf, docs)
  end
end
exports.plugin = plugin

return exports