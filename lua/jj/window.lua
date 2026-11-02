local M = {}

local WIDTH_FRACTION = 0.8
local HEIGHT_FRACTION = 0.8

local MENU_HEIGHT = 2
local MENU_SEPARATOR = "─"
local MENU_DELIMITER = " | "

local CONTENT_BORDER = { "╭", "─", "╮", "│", "", "", "", "│" }
local MENU_BORDER = { "", "", "", "│", "╯", "─", "╰", "│" }

local function layout()
  local width = math.floor(vim.o.columns * WIDTH_FRACTION)
  local total_height = math.floor(vim.o.lines * HEIGHT_FRACTION)
  local content_height = total_height - MENU_HEIGHT
  return {
    width = width,
    content_height = content_height,
    col = math.floor((vim.o.columns - width) / 2),
    row = math.floor((vim.o.lines - total_height) / 2),
  }
end

local function content_config(frame)
  return {
    relative = "editor",
    width = frame.width,
    height = frame.content_height,
    col = frame.col,
    row = frame.row,
    style = "minimal",
    border = CONTENT_BORDER,
    title = "jj",
    title_pos = "center",
  }
end

local function menu_config(frame)
  return {
    relative = "editor",
    width = frame.width,
    height = MENU_HEIGHT,
    col = frame.col,
    row = frame.row + 1 + frame.content_height,
    style = "minimal",
    border = MENU_BORDER,
    focusable = false,
    zindex = 51,
  }
end

local function menu_lines(actions, width)
  local labels = {}
  for _, action in ipairs(actions) do
    table.insert(labels, action.key .. ": " .. action.description)
  end
  local separator = string.rep(MENU_SEPARATOR, width)
  local menu_text = table.concat(labels, MENU_DELIMITER)
  return { separator, menu_text }
end

local function create_menu_buffer(actions, width)
  local buffer = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buffer, 0, -1, false, menu_lines(actions, width))
  vim.bo[buffer].bufhidden = "wipe"
  vim.bo[buffer].filetype = "jj-menu"
  vim.bo[buffer].modifiable = false
  return buffer
end

local HIGHLIGHT_NAMESPACE = vim.api.nvim_create_namespace("jj")

local HIGHLIGHT_BY_CODE = {
  A = "JjAdded",
  M = "JjModified",
  D = "JjDeleted",
}

local function define_highlights()
  vim.api.nvim_set_hl(0, "JjAdded", { fg = "#98c379", ctermfg = "Green", default = true })
  vim.api.nvim_set_hl(0, "JjModified", { fg = "#56b6c2", ctermfg = "Cyan", default = true })
  vim.api.nvim_set_hl(0, "JjDeleted", { fg = "#e06c75", ctermfg = "Red", default = true })
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

function M.is_open()
  return current_window ~= nil and vim.api.nvim_win_is_valid(current_window)
end

function M.update(lines)
  local buffer = vim.api.nvim_win_get_buf(current_window)
  vim.bo[buffer].modifiable = true
  vim.api.nvim_buf_set_lines(buffer, 0, -1, false, lines)
  highlight_lines(buffer, lines)
  vim.bo[buffer].modifiable = false
  vim.api.nvim_set_current_win(current_window)
end

local function close_if_valid(window)
  if vim.api.nvim_win_is_valid(window) then vim.api.nvim_win_close(window, true) end
end

function M.open(lines, actions)
  actions = actions or {}
  local frame = layout()
  local buffer = create_buffer(lines)
  local window = vim.api.nvim_open_win(buffer, true, content_config(frame))
  local menu_buffer = create_menu_buffer(actions, frame.width)
  local menu_window = vim.api.nvim_open_win(menu_buffer, false, menu_config(frame))
  current_window = window
  local function close()
    close_if_valid(menu_window)
    close_if_valid(window)
  end
  vim.keymap.set("n", "<Esc>", close, { buffer = buffer, nowait = true })
  for _, action in ipairs(actions) do
    vim.keymap.set("n", action.key, action.callback, { buffer = buffer, nowait = true })
  end
  vim.api.nvim_create_autocmd("WinLeave", {
    buffer = buffer,
    once = true,
    callback = function() vim.schedule(close) end,
  })
  return window
end

return M
