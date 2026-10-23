local T = MiniTest.new_set()

T["harness runs"] = function() MiniTest.expect.equality(1 + 1, 2) end

T["loads vendored mini.test"] = function()
  local path = debug.getinfo(require("mini.test").setup, "S").source
  MiniTest.expect.equality(path:find("tests/lua/mini/test.lua", 1, true) ~= nil, true)
end

return T
