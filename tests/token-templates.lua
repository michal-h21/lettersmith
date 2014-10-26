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

  local rendered_2 = tokens.render(template, {
    first = "Joe"
  })

  equal(rendered_2, "Hello, my name is Joe ", "Renders empty strings for tokens with no match")

  local template_3 = ":foo-:bar"
  local rendered_3 = tokens.render(template_3, {
    foo = "hello",
    bar = "world"
  })

  equal(rendered_3, "hello-world", "Tokens do not contain -")
end)