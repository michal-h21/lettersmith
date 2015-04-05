--[[
Lettersmith Debug

Debugging plugin for Lettersmith which provides a verbose version of
`transducers.comp`. These functions insert a serialization xform between every
pair of functions in the composed pipeline. This writes every doc object as it
goes through each stage of the composed pipeline.

Three functions are provided:

comp_filter(predicate, write_fn)
  This is a function which returns a debug version of `transducers.comp`, which
  serializes:
  * if `predicate` is a function: only the docs that pass `predicate` (default:
    return true) or
  * if `predicate` is a number: the first `predicate` docs.
  The serialized docs are written using `write_fn` (default: io.write)
  which could also be a collector, or could log the output to a file.

comp(z,y,...)
  This is the 'default' debug version of `comp`, which serializes every doc at
  each pipeline stage and writes it to stdout.

comp_filter_diff(predicate, write_fn)
  Like comp_filter, it returns a debug version of `transducers.comp`, but it
  serializes the differences between results of successive pipeline stages
  instead of the full doc tables.

  Example usage:
-- [...]
-- only print debugging info for the first doc 
local comp = require("lettersmith.debug").comp_filter(1)

local paths = lettersmith.paths("raw")
local gen = comp(render_permalinks(":slug"),
                 render_mustache("templates/page.html"),
                 markdown,
                 docs)
lettersmith.build("www", gen(paths))

--]]

local exports = {}
local serialization = require("lettersmith.serialization")
local serialize, serialize_diff = serialization.serialize, serialization.get_serialize_diff()
local transducers = require("lettersmith.transducers")
local comp, reduce, id = transducers.comp, transducers.reduce, transducers.id

local function getname(n)
  return "Transformations left: "..n.."\n"
end 

local function dbg_comp_filter(predicate, write_fn)
  return function (z,y,...)
    local n_transforms = 0
    local function dbg_comp2(z_,y_)
      n_transforms = n_transforms + 1
      return comp(z_,serialize(getname(n_transforms),predicate,write_fn),y_)
    end
    -- Seed `id` is the last function in the pipeline, as the functions are
    -- called in reverse order (right to left). The identity function closes
    -- the chain to make sure the result of the last step of the pipeline is
    -- also serialized.
    return reduce(dbg_comp2, id, ipairs{z or id, y, ...})
  end
end
exports.comp_filter = dbg_comp_filter
exports.comp = dbg_comp_filter() -- no filter, just a 'verbose' comp

local function getname_diff(n)
  return "Diff -- transformations left: "..n.."\n"
end

local function dbg_comp_filter_diff(predicate, write_fn)
  return function (z,y,...)
    local n_transforms = 0
    local function dbg_comp2(z_,y_)
      n_transforms = n_transforms + 1
      return comp(z_,serialize_diff(getname_diff(n_transforms),predicate,write_fn,n_transforms==1),y_)
    end
    return reduce(dbg_comp2, id, ipairs{z or id, y, ...})
  end
end
exports.comp_filter_diff = dbg_comp_filter_diff

return exports

