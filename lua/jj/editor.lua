local window = require("jj.window")

local M = {}

local WIDTH_RATIO = 0.6
local HEIGHT = 12

local function editor_config(change_id)
  local width = math.floor(vim.o.columns * WIDTH_RATIO)
  return {
    relative = "editor",
    width = width,
    height = HEIGHT,
    col = math.floor((vim.o.columns - width) / 2),
    row = math.floor((vim.o.lines - HEIGHT) / 2),
    style = "minimal",
    border = "rounded",
    title = "describe " .. change_id,
    title_pos = "center",
    zindex = 60,
  }
end

local function message_lines(text)
  local trimmed = text:gsub("%s+$", "")
  return vim.split(trimmed, "\n", { plain = true })
end

local function create_buffer(change_id, text)
  local buffer = vim.api.nvim_create_buf(false, false)
  vim.api.nvim_buf_set_name(buffer, "jj://describe/" .. change_id)
  vim.bo[buffer].buftype = "acwrite"
  vim.bo[buffer].bufhidden = "wipe"
  vim.bo[buffer].swapfile = false
  vim.bo[buffer].filetype = "jjdescription"
  vim.api.nvim_buf_set_lines(buffer, 0, -1, false, message_lines(text))
  vim.bo[buffer].modified = false
  return buffer
end

local function restore_focus(return_window)
  if vim.api.nvim_win_is_valid(return_window) then
    vim.api.nvim_set_current_win(return_window)
  end
end

function M.open(change_id, text, on_save)
  local return_window = vim.api.nvim_get_current_win()
  local buffer = create_buffer(change_id, text)
  local editor = vim.api.nvim_open_win(buffer, true, editor_config(change_id))
  window.register_popup(editor)
  local saved_message

  vim.api.nvim_create_autocmd("BufWriteCmd", {
    buffer = buffer,
    callback = function()
      local lines = vim.api.nvim_buf_get_lines(buffer, 0, -1, false)
      saved_message = table.concat(lines, "\n")
      vim.bo[buffer].modified = false
    end,
  })

  vim.api.nvim_create_autocmd("WinClosed", {
    pattern = tostring(editor),
    once = true,
    callback = function()
      vim.schedule(function()
        restore_focus(return_window)
        if saved_message then on_save(saved_message) end
      end)
    end,
  })
  return editor
end

return M
