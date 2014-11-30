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

local reducers = require("lettersmith.reducers")
local reject = reducers.reject

local function is_doc_path_prefixed_with_underscore(doc)
  -- Treat any document path that starts with an underscore as a draft.
  return doc.relative_filepath:find("^_")
end

-- Reject all draft docs.
local function use_drafts(docs)
  return reject(is_doc_path_prefixed_with_underscore, docs)
end
exports.use_drafts = use_drafts

return exports