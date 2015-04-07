--[[
Lettersmith Hash

Returns a transformer that fills in the 'hash' metadata field of a docs iterator.
This field contains the 32 hexadecimal digits of the md5sum of the document contents.
Fields from document take precedence.
--]]
local map = require("lettersmith.transducers").map
local transformer = require("lettersmith.lazy").transformer
local extend = require("lettersmith.table_utils").extend
local md5sum = require("md5").sumhexa

return transformer(map(function(doc)
  return extend({ hash=md5sum(doc.contents) }, doc)
end))
