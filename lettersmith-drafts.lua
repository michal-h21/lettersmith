local list = require('colist')
local reject = list.reject

return function (docs)
  -- Reject all documents that are drafts.
  -- Returns a new generator list of documents that are not drafts.
  return reject(docs, function (doc)
    return doc.draft
  end)
end