local cli = require("jj.cli")
local colors = require("jj.colors")
local errors = require("jj.errors")
local window = require("jj.window")

local M = {}

function M.setup(opts)
  opts = opts or {}
  colors.set(opts.colors)
end

local function status_actions()
  return {
    { key = "r", description = "refresh", callback = M.status_open },
  }
end

local function fetch_view()
  local output, status_err = cli.status()
  if not output then return nil, status_err end
  local commits, commits_err = cli.commits()
  if not commits then return nil, commits_err end
  local lines = vim.split(output, "\n", { trimempty = true })
  return { lines = lines, commits = commits }
end

function M.status_open()
  local view, err = fetch_view()
  if not view then
    errors.log_error(err)
    return
  end
  if window.is_open() then
    window.update(view.lines, view.commits)
    return
  end
  window.open(view.lines, status_actions(), view.commits)
end

return M
