local list = require('colist')
local map = list.map

local util = require('util')
local merge = util.merge

return function (docs, meta)
  -- Add metadata to all documents.
  -- Returns new list of documents with metadata mixed in.
  -- Fields from document take precidence.
  return map(docs, function (doc)
    return merge(meta, doc)
  end)
end