local consts = require("jj.consts")
local cli = require("jj.cli")
local errors = require("jj.errors")
local tree = require("jj.tree")
local view = require("jj.view")

local M = {}

function M.open(revision)
  local lines, err = cli.show(revision)
  if not lines then
    errors.log_error(err)
    return
  end
  local buffer = view.show({
    name = consts.URI_PREFIX .. "change/" .. view.short(revision),
    filetype = "jj-change",
    lines = lines,
    keys = { e = function() tree.open(revision, "") end },
  })
  vim.bo[buffer].syntax = "diff"
end

return M
