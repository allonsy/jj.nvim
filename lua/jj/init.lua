local cli = require("jj.cli")
local errors = require("jj.errors")
local window = require("jj.window")

local M = {}

function M.status_open()
  local output, err = cli.status()
  if not output then
    errors.log_error(err)
    return
  end
  local lines = vim.split(output, "\n", { trimempty = true })
  window.open(lines)
end

return M
