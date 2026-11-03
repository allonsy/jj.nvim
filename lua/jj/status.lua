local cli = require("jj.cli")
local commit_lines = require("jj.commit_lines")
local editor = require("jj.editor")
local errors = require("jj.errors")
local selector = require("jj.select")
local window = require("jj.window")

local M = {}

local current_view

local function refresh_after(operation)
  local ok, err = operation()
  if not ok then
    errors.log_error(err)
    return
  end
  M.open()
end

local function file_path_of(line)
  return line and line:match("^[AMD] (.+)$")
end

local function parents_of(view)
  return vim.list_slice(view.commits, 2)
end

local function choose_parent(parents, on_choice)
  local labels = commit_lines.render_choices(parents)
  selector.open(labels, "squash into", function(index)
    on_choice(parents[index])
  end)
end

local function squash_file_into_parents(path)
  local parents = parents_of(current_view)
  if #parents == 0 then return end
  local function squash_into(parent)
    refresh_after(function() return cli.squash_file(path, parent.change_id) end)
  end
  if #parents == 1 then
    squash_into(parents[1])
    return
  end
  choose_parent(parents, squash_into)
end

local function on_squash(context)
  if context.pane == "commits" then
    local commit = current_view.commits[context.index]
    if not commit then return end
    refresh_after(function() return cli.squash_commit(commit.change_id) end)
    return
  end
  local path = file_path_of(context.line)
  if not path then return end
  squash_file_into_parents(path)
end

local function on_restore(context)
  if context.pane == "commits" then
    local commit = current_view.commits[context.index]
    if not commit then return end
    refresh_after(function() return cli.unsquash_commit(commit.change_id) end)
    return
  end
  local path = file_path_of(context.line)
  if not path then return end
  refresh_after(function() return cli.restore_file(path) end)
end

local function on_describe(context)
  if context.pane ~= "commits" then return end
  local commit = current_view.commits[context.index]
  if not commit then return end
  local text, err = cli.get_description(commit.change_id)
  if not text then
    errors.log_error(err)
    return
  end
  local function save(message)
    refresh_after(function() return cli.describe(commit.change_id, message) end)
  end
  editor.open(commit.change_id, text, save)
end

local function on_abandon(context)
  if context.pane ~= "commits" then return end
  local commit = current_view.commits[context.index]
  if not commit then return end
  refresh_after(function() return cli.abandon(commit.change_id) end)
end

local function on_new()
  refresh_after(cli.new)
end

local function on_fork()
  refresh_after(cli.fork)
end

local function status_actions()
  return {
    { key = "r", description = "refresh", callback = M.open },
    { key = "s", description = "squash", callback = on_squash },
    { key = "u", description = "restore", callback = on_restore },
    { key = "d", description = "describe", callback = on_describe },
    { key = "x", description = "abandon", callback = on_abandon },
    { key = "n", description = "new", callback = on_new },
    { key = "f", description = "fork", callback = on_fork },
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

function M.open()
  local view, err = fetch_view()
  if not view then
    errors.log_error(err)
    return
  end
  current_view = view
  if window.is_open() then
    window.update(view.lines, view.commits)
    return
  end
  window.open(view.lines, status_actions(), view.commits)
end

return M
