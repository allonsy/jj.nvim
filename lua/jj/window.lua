local M = {}

local WIDTH_FRACTION = 0.8
local HEIGHT_FRACTION = 0.8

local function float_config()
  local width = math.floor(vim.o.columns * WIDTH_FRACTION)
  local height = math.floor(vim.o.lines * HEIGHT_FRACTION)
  return {
    relative = "editor",
    width = width,
    height = height,
    col = math.floor((vim.o.columns - width) / 2),
    row = math.floor((vim.o.lines - height) / 2),
    style = "minimal",
    border = "rounded",
    title = "jj",
    title_pos = "center",
  }
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

function M.open(lines, on_refresh)
  local buffer = create_buffer(lines)
  local window = vim.api.nvim_open_win(buffer, true, float_config())
  current_window = window
  local function close()
    if vim.api.nvim_win_is_valid(window) then vim.api.nvim_win_close(window, true) end
  end
  vim.keymap.set("n", "<Esc>", close, { buffer = buffer, nowait = true })
  if on_refresh then vim.keymap.set("n", "r", on_refresh, { buffer = buffer, nowait = true }) end
  vim.api.nvim_create_autocmd("WinLeave", {
    buffer = buffer,
    once = true,
    callback = function() vim.schedule(close) end,
  })
  return window
end

return M
