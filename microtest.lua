local exports = {}

local function suite(message, callback)
  print(message)
  callback()
end
exports.suite = suite

local function test(truthy, message)
  assert(truthy, message)
  print('• ' .. message)
end
exports.test = test

return exports