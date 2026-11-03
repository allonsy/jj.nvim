local colors = require("jj.colors")
local commit_lines = require("jj.commit_lines")
local options = require("jj.options")

local M = {}

local MAX_COMMIT_ROWS = 6
local COMMIT_SEPARATOR_ROWS = 1
local COMMIT_BOTTOM_BORDER_ROWS = 1

local function layout(commit_count)
  local resolved = options.resolve()
  local width = math.floor(vim.o.columns * resolved.width)
  local total_height = math.floor(vim.o.lines * resolved.height)
  local commits_height = math.min(math.max(commit_count, 1), MAX_COMMIT_ROWS)
  local files_height = total_height - commits_height - COMMIT_SEPARATOR_ROWS - COMMIT_BOTTOM_BORDER_ROWS - 1
  return {
    width = width,
    files_height = files_height,
    commits_height = commits_height,
    col = math.floor((vim.o.columns - width) / 2),
    row = math.floor((vim.o.lines - total_height) / 2),
  }
end

local function content_config(frame)
  return {
    relative = "editor",
    width = frame.width,
    height = frame.files_height,
    col = frame.col,
    row = frame.row,
    style = "minimal",
    border = options.borders().content,
    title = "jj",
    title_pos = "center",
  }
end

local function commits_config(frame)
  return {
    relative = "editor",
    width = frame.width,
    height = frame.commits_height,
    col = frame.col,
    row = frame.row + 1 + frame.files_height,
    style = "minimal",
    border = options.borders().commits,
  }
end

local HIGHLIGHT_NAMESPACE = vim.api.nvim_create_namespace("jj")

local HIGHLIGHT_BY_CODE = {
  A = "JjAdded",
  M = "JjModified",
  D = "JjDeleted",
}

local COMMIT_NAMESPACE = vim.api.nvim_create_namespace("jj-commits")

local function define_highlights()
  colors.apply()
end

local function highlight_lines(buffer, lines)
  vim.api.nvim_buf_clear_namespace(buffer, HIGHLIGHT_NAMESPACE, 0, -1)
  for index, line in ipairs(lines) do
    local code = line:sub(1, 1)
    local group = HIGHLIGHT_BY_CODE[code]
    if group and line:sub(2, 2) == " " then
      vim.api.nvim_buf_set_extmark(buffer, HIGHLIGHT_NAMESPACE, index - 1, 0, {
        end_row = index - 1,
        end_col = #line,
        hl_group = group,
      })
    end
  end
end

local function fill_commits_buffer(buffer, commits)
  local lines, spans = commit_lines.render_commits(commits)
  vim.bo[buffer].modifiable = true
  vim.api.nvim_buf_set_lines(buffer, 0, -1, false, lines)
  vim.api.nvim_buf_clear_namespace(buffer, COMMIT_NAMESPACE, 0, -1)
  for _, span in ipairs(spans) do
    vim.api.nvim_buf_set_extmark(buffer, COMMIT_NAMESPACE, span.row, span.start_col, {
      end_row = span.row,
      end_col = span.end_col,
      hl_group = span.group,
    })
  end
  vim.bo[buffer].modifiable = false
end

local function create_commits_buffer(commits)
  define_highlights()
  local buffer = vim.api.nvim_create_buf(false, true)
  vim.bo[buffer].buftype = "nofile"
  vim.bo[buffer].bufhidden = "wipe"
  vim.bo[buffer].swapfile = false
  vim.bo[buffer].filetype = "jj-commits"
  fill_commits_buffer(buffer, commits)
  return buffer
end

local function create_buffer(lines)
  define_highlights()
  local buffer = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buffer, 0, -1, false, lines)
  highlight_lines(buffer, lines)
  vim.bo[buffer].buftype = "nofile"
  vim.bo[buffer].bufhidden = "wipe"
  vim.bo[buffer].swapfile = false
  vim.bo[buffer].filetype = "jj"
  vim.bo[buffer].modifiable = false
  return buffer
end

local current_window
local current_commits_window

function M.is_open()
  return current_window ~= nil and vim.api.nvim_win_is_valid(current_window)
end

function M.update(lines, commits)
  local buffer = vim.api.nvim_win_get_buf(current_window)
  vim.bo[buffer].modifiable = true
  vim.api.nvim_buf_set_lines(buffer, 0, -1, false, lines)
  highlight_lines(buffer, lines)
  vim.bo[buffer].modifiable = false
  local commits_buffer = vim.api.nvim_win_get_buf(current_commits_window)
  fill_commits_buffer(commits_buffer, commits)
  vim.api.nvim_set_current_win(current_window)
end

local popup_window

function M.register_popup(popup)
  popup_window = popup
end

local function is_jj_window(candidate)
  return candidate == current_window
    or candidate == current_commits_window
    or candidate == popup_window
end

local function pane_context(pane)
  local row = vim.api.nvim_win_get_cursor(0)[1]
  local context = { pane = pane, index = row }
  if pane == "files" then context.line = vim.api.nvim_get_current_line() end
  return context
end

local function close_if_valid(window)
  if vim.api.nvim_win_is_valid(window) then vim.api.nvim_win_close(window, true) end
end

function M.open(lines, actions, commits)
  actions = actions or {}
  commits = commits or {}
  local frame = layout(#commits)
  local buffer = create_buffer(lines)
  local window = vim.api.nvim_open_win(buffer, true, content_config(frame))
  local commits_buffer = create_commits_buffer(commits)
  local commits_window = vim.api.nvim_open_win(commits_buffer, false, commits_config(frame))
  current_window = window
  current_commits_window = commits_window
  local function close()
    close_if_valid(commits_window)
    close_if_valid(window)
  end
  local function switch_pane()
    local target = window
    if vim.api.nvim_get_current_win() == window then target = commits_window end
    vim.api.nvim_set_current_win(target)
  end
  local function close_unless_jj_window()
    if not is_jj_window(vim.api.nvim_get_current_win()) then close() end
  end
  local panes = { { buffer = buffer, name = "files" }, { buffer = commits_buffer, name = "commits" } }
  for _, pane in ipairs(panes) do
    local pane_buffer = pane.buffer
    vim.keymap.set("n", "<Esc>", close, { buffer = pane_buffer, nowait = true })
    vim.keymap.set("n", "<Tab>", switch_pane, { buffer = pane_buffer, nowait = true })
    for _, action in ipairs(actions) do
      local function run_action()
        action.callback(pane_context(pane.name))
      end
      vim.keymap.set("n", action.key, run_action, { buffer = pane_buffer, nowait = true })
    end
    vim.api.nvim_create_autocmd("WinLeave", {
      buffer = pane_buffer,
      callback = function() vim.schedule(close_unless_jj_window) end,
    })
  end
  return window
end

return M
