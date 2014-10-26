local microtest = require("microtest")
local suite = microtest.suite
local equal = microtest.equal
local test = microtest.test

local tokens = require("token-templates")

suite("render()", function ()
  local template = "Hello, my name is :first :last"
  local rendered = tokens.render(template, {
    first = "Joe",
    last = "Schmoe"
  })

  equal(rendered, "Hello, my name is Joe Schmoe", "Renders template tokens")

  local rendered2 = tokens.render(template, {
    first = "Joe"
  })

  equal(rendered2, "Hello, my name is Joe ", "Renders empty strings for tokens with no match")
end)