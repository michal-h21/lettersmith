--[[
Lettersmith Drafts

Remove drafts from rendered docs. A drafts is any document that has `draft: yes`
in the headmatter section.

Usage:

    local use_drafts = require('lettersmith.drafts').use_drafts
    local lettersmith = require('lettersmith')

    lettersmith.generate("raw", "out", use_drafts)
--]]
local exports = {}

local transducers = require("transducers")
local reject = transducers.reject

local lazily = require("lazily")

local reject_drafts = reject(function (doc)
  -- Treat any document path that starts with an underscore as a draft.
  return doc.relative_filepath:find("^_")
end)
exports.reject_drafts = reject_drafts

local function use_drafts(docs)
  return lazily.transform(reject_drafts, docs)
end
exports.use_drafts = use_drafts

return exports