local window = require("jj.window")

local M = {}

local MIN_WIDTH = 20

local function widest(items)
  local width = MIN_WIDTH
  for _, item in ipairs(items) do
    width = math.max(width, vim.fn.strdisplaywidth(item))
  end
  return width
end

local function popup_config(items, title)
  local width = widest(items)
  local height = #items
  return {
    relative = "editor",
    width = width,
    height = height,
    col = math.floor((vim.o.columns - width) / 2),
    row = math.floor((vim.o.lines - height) / 2),
    style = "minimal",
    border = "rounded",
    title = title,
    title_pos = "center",
    zindex = 60,
  }
end

function M.open(items, title, on_choice)
  local return_window = vim.api.nvim_get_current_win()
  local buffer = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buffer, 0, -1, false, items)
  vim.bo[buffer].bufhidden = "wipe"
  vim.bo[buffer].modifiable = false
  vim.bo[buffer].filetype = "jj-select"
  local popup = vim.api.nvim_open_win(buffer, true, popup_config(items, title))
  vim.wo[popup].cursorline = true
  window.register_popup(popup)

  local function close()
    if vim.api.nvim_win_is_valid(popup) then vim.api.nvim_win_close(popup, true) end
    if vim.api.nvim_win_is_valid(return_window) then vim.api.nvim_set_current_win(return_window) end
  end
  local function choose()
    local index = vim.api.nvim_win_get_cursor(popup)[1]
    close()
    on_choice(index)
  end
  local keymap_options = { buffer = buffer, nowait = true }
  vim.keymap.set("n", "<CR>", choose, keymap_options)
  vim.keymap.set("n", "<Esc>", close, keymap_options)
  vim.keymap.set("n", "q", close, keymap_options)
  return popup
end

return M
