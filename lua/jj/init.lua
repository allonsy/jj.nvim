local colors = require("jj.colors")
local status = require("jj.status")

local M = {}

function M.setup(opts)
  opts = opts or {}
  colors.set(opts.colors)
end

function M.status_open()
  status.open()
end

return M
