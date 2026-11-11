local colors = require("jj.colors")

local M = {}

local NAMESPACE = vim.api.nvim_create_namespace("jj-view")

local buffers = {}

local function buffer_named(name)
  local buffer = buffers[name]
  if buffer and vim.api.nvim_buf_is_valid(buffer) then return buffer end
  buffer = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_name(buffer, name)
  vim.bo[buffer].buftype = "nofile"
  vim.bo[buffer].bufhidden = "hide"
  vim.bo[buffer].swapfile = false
  buffers[name] = buffer
  return buffer
end

local function fill(buffer, lines, spans, prefixes)
  vim.bo[buffer].readonly = false
  vim.bo[buffer].modifiable = true
  vim.api.nvim_buf_set_lines(buffer, 0, -1, false, lines)
  vim.api.nvim_buf_clear_namespace(buffer, NAMESPACE, 0, -1)
  for _, span in ipairs(spans) do
    vim.api.nvim_buf_set_extmark(buffer, NAMESPACE, span.row, span.start_col, {
      end_row = span.row,
      end_col = span.end_col,
      hl_group = span.group,
    })
  end
  for index, prefix in ipairs(prefixes) do
    vim.api.nvim_buf_set_extmark(buffer, NAMESPACE, index - 1, 0, {
      virt_text = prefix,
      virt_text_pos = "inline",
      right_gravity = false,
    })
  end
  vim.bo[buffer].modifiable = false
  vim.bo[buffer].readonly = true
end

local function map_keys(buffer, keys)
  for key, callback in pairs(keys) do
    local function on_key()
      callback(vim.api.nvim_win_get_cursor(0)[1])
    end
    vim.keymap.set("n", key, on_key, { buffer = buffer, nowait = true })
  end
end

-- Shows a read-only buffer in the current window. Views are ordinary
-- buffers, so the jumplist (<C-o>) walks back through them.
--
-- spec.name      buffer name; showing the same name again reuses the buffer
-- spec.lines     buffer contents
-- spec.spans     highlights as { row, start_col, end_col, group }
-- spec.prefixes  optional per-line inline virtual text, drawn before the
--                line without being part of it: a list of
--                { text, group } chunks for each line
-- spec.filetype  optional filetype
-- spec.keys      key -> callback(cursor_row)
-- spec.row       optional line to put the cursor on
function M.show(spec)
  colors.apply()
  local buffer = buffer_named(spec.name)
  fill(buffer, spec.lines, spec.spans or {}, spec.prefixes or {})
  if spec.filetype and vim.bo[buffer].filetype ~= spec.filetype then
    vim.bo[buffer].filetype = spec.filetype
  end
  map_keys(buffer, spec.keys or {})
  if vim.api.nvim_get_current_buf() ~= buffer then
    vim.cmd("normal! m'")
    vim.api.nvim_win_set_buf(0, buffer)
  end
  local last_row = vim.api.nvim_buf_line_count(buffer)
  local row = math.min(math.max(spec.row or 1, 1), last_row)
  vim.api.nvim_win_set_cursor(0, { row, 0 })
  return buffer
end

function M.short(revision)
  return revision:sub(1, 12)
end

return M
