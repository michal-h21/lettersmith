local microtest = require("microtest")
local suite = microtest.suite
local test = microtest.test
local equal = microtest.equal

local table_utils = require("table_utils")
local map_table = table_utils.map

suite("table_utils.map(t, transform)", function ()
  local a = {1, 2, 3}

  local function square(a)
    return a * a
  end

  local b = map_table(a, square)

  equal(b[1], 1, "Maps value at index")
  equal(b[2], 4, "Maps value at index")
end)