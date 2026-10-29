local cli = require("jj.cli")
local window = require("jj.window")

local M = {}

function M.status_open()
  local output = cli.status()
  if not output then return end
  local lines = vim.split(output, "\n", { trimempty = true })
  window.open(lines)
end

return M
