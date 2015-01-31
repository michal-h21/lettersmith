--[[
Lettersmith Meta

Add metadata to every doc object. This is useful for things like site meta.
--]]
local transducers = require('lettersmith.transducers')
local map = transducers.map

local table_utils = require("lettersmith.table_utils")
local merge = table_utils.merge

local function use_meta(meta)
  return map(function (doc)
    return merge(meta, doc)
  end)
end

return use_meta