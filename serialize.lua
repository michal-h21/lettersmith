--[[
Lettersmith Serialize

Serialization plugin for Lettersmith. Useful for debugging.

This function takes three arguments:
 - `info_string`: to be written at the top of each serialization (default: "")
 - `predicate`: a predicate function (default: return true)
 or 
   `n`: number of docs that should be serialized
 - `write_fn`: function that is called with the serialized doc string as
 argument (default: io.write).
 
This function returns a transformer that serializes and writes the documents
that pass `predicate`, but does not change them.
--]]

local map = require("lettersmith.transducers").map
local transformer = require("lettersmith.lazy").transformer
local serpent = require("serpent")
local serpent_opts = {comment=false, nocode=true,}
local serialize_n
local function allpass()
  return true
end

local function serialize(info_string, predicate, write_fn)
  if type(predicate)=="number" then
    return serialize_n(info_string, predicate, write_fn)
  end
  info_string = info_string or ""
  predicate = predicate or allpass
  write_fn = write_fn or io.write
  return transformer(map(function(doc)
    if predicate(doc) then
      write_fn(info_string,serpent.block(doc,serpent_opts).."\n")
    end
    return doc
  end))
end

function serialize_n(info_string, n, write_fn)
  n = n or 1
  local function first_n()
    n = n-1
    return n>=0
  end
  return serialize(info_string, first_n, write_fn)
end

return serialize

