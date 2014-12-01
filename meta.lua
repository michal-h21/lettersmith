--[[
Lettersmith Meta

Add metadata to every doc object. This is useful for things like site meta.

Usage:

    local use_meta = require('lettersmith.meta').use_meta
    local lettersmith = require('lettersmith')

    lettersmith.generate("raw", "out", use_meta { site_title = "My website" })
--]]
local exports = {}

local reducers = require("lettersmith.reducers")
local map = reducers.map

local table_utils = require("lettersmith.table_utils")
local merge = table_utils.merge

local function use_meta(meta)
  return function (docs)
    return map(function (doc)
      return merge(meta, doc)
    end, docs)
  end
end
exports.use_meta = use_meta

return exports