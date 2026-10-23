local T = MiniTest.new_set()

T["harness runs"] = function() MiniTest.expect.equality(1 + 1, 2) end

T["loads vendored mini.test"] = function()
  local mini_test = require("mini.test").setup
  local path = debug.getinfo(mini_test, "S").source
  local mini_test_file_search_results = path:find("tests/lua/mini/test.lua", 1, true)
  MiniTest.expect.equality(mini_test_file_search_results ~= nil, true)
end

return T
