local micro = {}

function micro.suite(message, callback)
  print(message)
  callback()
end

function micro.test(truthy, message)
  assert(truthy, message)
  print('• ' .. message)
end

function micro.equal(a, b, message)
  assert(a == b, "Failed! " .. message .. " (" .. a .. " ~= " .. b .. ")")
  print("• " .. message)
end

return micro