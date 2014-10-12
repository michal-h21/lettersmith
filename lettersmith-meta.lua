local listable = require('listable')
local merge = listable.merge
local map = listable.map

local exports = {}

function process(docs, meta)
  -- Add metadata to all documents.
  -- Returns new list of documents with metadata mixed in.
  -- Fields from document take precidence.
  return map(docs, function (doc)
    return merge(meta, doc)
  end)
end
exports.process = process

return exports