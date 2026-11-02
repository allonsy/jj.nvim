local colors = require("jj.colors")
local options = require("jj.options")
local status = require("jj.status")

local M = {}

function M.setup(opts)
  opts = opts or {}
  colors.set(opts.colors)
  local window_options = {
    width = opts.width,
    height = opts.height,
    border = opts.border,
  }
  options.set(window_options)
end

function M.status_open()
  status.open()
end

return M
