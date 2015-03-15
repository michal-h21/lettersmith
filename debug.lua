--[[
Lettersmith Debug

Debugging plugin for Lettersmith which provides a verbose version of
`transducers.comp`. These functions insert a serialization xform between every
pair of functions in the composed pipeline. This writes every doc object as it
goes through each stage of the composed pipeline.

Two functions are provided:

comp_filter(predicate, write_fn)
  This is a function which returns a debug version of `transducers.comp`, which
  serializes:
  * if `predicate` is a function: only the docs that pass `predicate` (default:
    return true) or
  * if `predicate` is a number: the first `predicate` docs.
  The serialized docs are written using `write_fn` (default: io.write)
  which could also be a collector, or could log the output to a file.

comp(...)
  This is the 'default' debug version of `comp`, which serializes every doc at
  each pipeline stage and writes it to stdout.

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
local serialize = require("lettersmith.serialize")
local transducers = require("lettersmith.transducers")
local comp2, reduce, id = transducers.comp2, transducers.reduce, transducers.id

local function getname(n)
  return "Transformations left: "..n.."\n"
end 

local function dbg_comp_filter(predicate, write_fn)
  return function (z,y,...)
    local n_transforms = 0
    local function dbg_comp2(z_,y_)
      n_transforms = n_transforms + 1
      return comp2(z_,comp2(serialize(getname(n_transforms),predicate,write_fn),y_))
    end
    return reduce(dbg_comp2, id, ipairs{z or id, y, ...})
  end
end

exports.comp_filter = dbg_comp_filter
exports.comp = dbg_comp_filter() -- no filter, just a 'verbose' comp

return exports

