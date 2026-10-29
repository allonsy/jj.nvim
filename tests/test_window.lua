local expect = MiniTest.expect

local STATUS_OUTPUT = "Working copy changes:\nA file.txt\nWorking copy : abc 123\n"

local original_status

local T = MiniTest.new_set({
  hooks = {
    pre_case = function()
      local cli = require("jj.cli")
      original_status = cli.status
      cli.status = function() return STATUS_OUTPUT end
    end,
    post_case = function()
      require("jj.cli").status = original_status
      vim.cmd("silent! %bwipeout!")
    end,
  },
})

local function open_window()
  require("jj").status_open()
  local window = vim.api.nvim_get_current_win()
  local buffer = vim.api.nvim_win_get_buf(window)
  return window, buffer
end

T["shows a centered rounded float titled jj"] = function()
  local window = open_window()
  local config = vim.api.nvim_win_get_config(window)

  expect.equality(config.relative, "editor")
  expect.equality(config.title[1][1], "jj")
  expect.equality(config.title_pos, "center")
  expect.equality(config.border[1], "╭")
  expect.equality(config.width, math.floor(vim.o.columns * 0.8))
  expect.equality(config.height, math.floor(vim.o.lines * 0.8))
  expect.equality(config.col, math.floor((vim.o.columns - config.width) / 2))
  expect.equality(config.row, math.floor((vim.o.lines - config.height) / 2))
end

T["shows the status output"] = function()
  local _, buffer = open_window()
  local lines = vim.api.nvim_buf_get_lines(buffer, 0, -1, false)

  expect.equality(lines, { "Working copy changes:", "A file.txt", "Working copy : abc 123" })
end

T["buffer is a read-only scratch buffer with filetype jj"] = function()
  local _, buffer = open_window()

  expect.equality(vim.bo[buffer].modifiable, false)
  expect.equality(vim.bo[buffer].buftype, "nofile")
  expect.equality(vim.bo[buffer].bufhidden, "wipe")
  expect.equality(vim.bo[buffer].filetype, "jj")
end

T["cursor still moves"] = function()
  local window = open_window()

  vim.cmd("normal! j")

  expect.equality(vim.api.nvim_win_get_cursor(window)[1], 2)
end

T["escape closes the window and wipes the buffer"] = function()
  local window, buffer = open_window()

  vim.api.nvim_feedkeys(vim.keycode("<Esc>"), "x", false)

  expect.equality(vim.api.nvim_win_is_valid(window), false)
  expect.equality(vim.api.nvim_buf_is_valid(buffer), false)
end

T["q is not bound"] = function()
  local _, buffer = open_window()
  local maps = vim.api.nvim_buf_get_keymap(buffer, "n")
  local bound = {}
  for _, map in ipairs(maps) do
    bound[map.lhs] = true
  end

  expect.equality(bound["q"], nil)
end

T["registers no user command or default keymap"] = function()
  expect.equality(vim.fn.exists(":JJ"), 0)
  expect.equality(vim.fn.maparg("<leader>jj", "n"), "")
end

return T
