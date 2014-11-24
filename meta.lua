--[[
Lettersmith Meta

Add metadata to every doc object. This is useful for things like site meta.

Usage:

    local use_meta = require('lettersmith.meta').use_meta
    local lettersmith = require('lettersmith')

    lettersmith.generate("raw", "out", use_meta { site_title = "My website" })
--]]
local exports = {}

local lazily = require("lettersmith.lazily")
local transducers = require("lettersmith.transducers")

local table_utils = require("lettersmith.table_utils")
local merge = table_utils.merge

local function map_meta(meta)
  return transducers.map(function (doc)
    return merge(meta, doc)
  end)
end
exports.map_meta = map_meta

local function use_meta(meta)
  local xf = map_meta(meta)

  return function (docs)
    return lazily.transform(xf, docs)
  end
end
exports.use_meta = use_meta

return exports