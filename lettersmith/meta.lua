--[[
Lettersmith Meta

Add metadata to every doc object. This is useful for things like site meta.
--]]
local map = require('lettersmith.transducers').map
local merge = require("lettersmith.table_utils").merge
local transformer = require("lettersmith.lazy").transformer

local function use_meta(meta)
  return transformer(map(function (doc)
    return merge(meta, doc)
  end))
end

return use_meta