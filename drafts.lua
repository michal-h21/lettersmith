--[[
Lettersmith Drafts

Remove drafts from rendered docs. A draft is any file who's name starts with
an underscore.
--]]
local reject = require("lettersmith.transducers").reject
local transformer = require("lettersmith.lazy").transformer
local path = require("lettersmith.path")

local function is_doc_path_prefixed_with_underscore(doc)
  -- Treat any document path that starts with an underscore as a draft.
  return path.basename(doc.relative_filepath):find("^_")
end

-- Remove all docs who's path is prefixed with an underscore.
local remove_drafts = transformer(reject(is_doc_path_prefixed_with_underscore))

return remove_drafts