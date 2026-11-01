local cli = require("jj.cli")
local errors = require("jj.errors")
local window = require("jj.window")

local M = {}

local function status_actions()
  return {
    { key = "r", description = "refresh", callback = M.status_open },
  }
end

function M.status_open()
  local output, err = cli.status()
  if not output then
    errors.log_error(err)
    return
  end
  local lines = vim.split(output, "\n", { trimempty = true })
  if window.is_open() then
    window.update(lines)
    return
  end
  window.open(lines, status_actions())
end

return M
