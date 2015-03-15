--[[
Lettersmith Serialize

Serialization plugin for Lettersmith. Useful for debugging.

Two functions are provided:

serialize(info_string, predicate, write_fn)
  This function takes three arguments:
  - `info_string`: to be written at the top of each serialization (default: "")
  - `predicate`: a predicate function (default: return true) 
   OR the number of docs that should be serialized (the first `predicate` docs)
  - `write_fn`: function that is called with the serialized doc string as
    argument (default: io.write).
  This function returns a transformer that serializes and writes the documents
  that pass `predicate`, but does not change them.

get_serialize_diff()
  This returns a stateful serialize_diff function which serializes only the
  difference between the current doc table and the one in the previous use of
  this serialize_diff in the pipeline. To do this, it keeps track of the
  previous doc. In addition to the arguments of the serialize function, it
  takes an optional `reset` flag (default: false) to indicate the end of the
  pipeline, in which case its state is reset _after_ the write.

Example usage:

-- [...]
local serialize = require("lettersmith.serialize").serialize
local diff = require("lettersmith.serialize").get_serialize_diff()

local paths = lettersmith.paths("raw")
local gen = comp(serialize("final_doc = "),
                 render_permalinks(":slug"),
                 render_mustache("templates/page.html"),
                 diff("diff_markdown_and_hash = ",nil,nil,true),
                 markdown,
                 hash,
                 diff("beginning = "),
                 docs)

lettersmith.build("www", gen(paths))

--]]

local exports = {}
local map = require("lettersmith.transducers").map
local transformer = require("lettersmith.lazy").transformer
local serpent = require("serpent")
local serpent_opts = {comment=false, nocode=true,}
local function allpass() return true end

-- If `predicate` is a number, `make_predicate` returns a function that
-- counts down from `predicate` and returns true `predicate` times.
-- Otherwise, return `predicate`, or if this is falsy, return allpass.
local function make_predicate(predicate)
  if type(predicate)=="number" then
    return function()
      predicate = predicate-1
      return predicate>=0
    end
  end
  return predicate or allpass
end

local function serialize(info_string, predicate, write_fn)
  info_string = info_string or ""
  predicate = make_predicate(predicate)
  write_fn = write_fn or io.write
  return transformer(map(function(doc)
    if predicate(doc) then
      write_fn(info_string,serpent.block(doc,serpent_opts).."\n")
    end
    return doc
  end))
end
exports.serialize = serialize

-- `diff` returns a table which summarizes the differences between t1 and t2.
local function diff(t1,t2)
  local t_diff = {}
  for k,v in pairs(t2) do
    if v~=t1[k] then
      t_diff[k]=v
    end
  end
  for k in pairs(t1) do
    if not t2[k] then
      t_diff[k]= "<removed>"
    end
  end
  return t_diff
end

-- Get a stateful function for serializing diffs.
local function get_serialize_diff()
  local doc_prev = {}
  return function(info_string, predicate, write_fn, reset)
    info_string = info_string or ""
    predicate = make_predicate(predicate)
    write_fn = write_fn or io.write
    return transformer(map(function(doc)
      if predicate(doc) then
        local doc_diff = diff(doc_prev,doc)
        write_fn(info_string,serpent.block(doc_diff,serpent_opts).."\n")
        doc_prev = doc
      end
      if reset then doc_prev = {} end
      return doc
    end))
  end
end
exports.get_serialize_diff = get_serialize_diff

return exports


