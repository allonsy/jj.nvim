local consts = require("jj.consts")
local cli = require("jj.cli")
local errors = require("jj.errors")
local view = require("jj.view")

local M = {}

-- Opens `path` as it was at `revision`, read-only, optionally on line `row`.
function M.open(revision, path, row)
  local lines, err = cli.file_show(revision, path)
  if not lines then
    errors.log_error(err)
    return
  end
  local buffer = view.show({
    name = consts.URI_PREFIX .. "file/" .. view.short(revision) .. "/" .. path,
    lines = lines,
    row = row,
  })
  vim.b[buffer].jj_file = { revision = revision, path = path }
  local filetype = vim.filetype.match({ filename = path, buf = buffer })
  if filetype and vim.bo[buffer].filetype ~= filetype then vim.bo[buffer].filetype = filetype end
end

return M
