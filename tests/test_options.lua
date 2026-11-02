local expect = MiniTest.expect

local T = MiniTest.new_set({
  hooks = {
    pre_case = function()
      local cli = require("jj.cli")
      cli.status = function() return "A file.txt\n" end
      cli.commits = function()
        return { { bookmarks = {}, change_id = "ab", commit_id = "12f", description = "x" } }
      end
      require("jj").setup()
    end,
    post_case = function()
      require("jj").setup()
      vim.cmd("silent! %bwipeout!")
    end,
  },
})

local function open_content_config()
  require("jj").status_open()
  local window = vim.api.nvim_get_current_win()
  return vim.api.nvim_win_get_config(window)
end

local function find_config_by_filetype(filetype)
  for _, candidate in ipairs(vim.api.nvim_list_wins()) do
    local buffer = vim.api.nvim_win_get_buf(candidate)
    if vim.bo[buffer].filetype == filetype then return vim.api.nvim_win_get_config(candidate) end
  end
end

T["defaults apply without setup"] = function()
  local config = open_content_config()

  expect.equality(config.width, math.floor(vim.o.columns * 0.8))
  expect.equality(config.border[1], "╭")
end

T["partial override changes only width"] = function()
  require("jj").setup({ width = 0.5 })
  local config = open_content_config()
  local total_height = math.floor(vim.o.lines * 0.8)

  expect.equality(config.width, math.floor(vim.o.columns * 0.5))
  expect.equality(config.height, total_height - 2 - 1 - 1)
  expect.equality(config.border[1], "╭")
end

T["full override applies width, height and border"] = function()
  require("jj").setup({ width = 0.6, height = 0.5, border = "double" })
  local config = open_content_config()
  local total_height = math.floor(vim.o.lines * 0.5)

  expect.equality(config.width, math.floor(vim.o.columns * 0.6))
  expect.equality(config.height, total_height - 2 - 1 - 1)
  expect.equality(config.border[1], "╔")
  local commits_config = find_config_by_filetype("jj-commits")
  expect.equality(commits_config.border[1], "╠")
  local menu_config = find_config_by_filetype("jj-menu")
  expect.equality(menu_config.border[5], "╝")
end

T["custom border table is used for the outer frame"] = function()
  local custom = { "a", "b", "c", "d", "e", "f", "g", "h" }
  require("jj").setup({ border = custom })
  local config = open_content_config()

  expect.equality(config.border[1], "a")
  expect.equality(config.border[8], "h")
end

T["setup again resets options not given"] = function()
  require("jj").setup({ width = 0.5, border = "single" })
  require("jj").setup({ height = 0.6 })
  local config = open_content_config()

  expect.equality(config.width, math.floor(vim.o.columns * 0.8))
  expect.equality(config.border[1], "╭")
end

return T
