local expect = MiniTest.expect

local original_cwd
local original_path
local original_notify
local notifications
local tmp_dirs = {}

local function tmpdir()
  local dir = vim.fn.resolve(vim.fn.tempname())
  vim.fn.mkdir(dir, "p")
  table.insert(tmp_dirs, dir)
  return dir
end

local function snapshot_layout()
  return {
    windows = #vim.api.nvim_list_wins(),
    buffers = #vim.api.nvim_list_bufs(),
  }
end

local T = MiniTest.new_set({
  hooks = {
    pre_case = function()
      original_cwd = vim.fn.getcwd()
      original_path = vim.env.PATH
      original_notify = vim.notify
      notifications = {}
      vim.notify = function(message, level)
        table.insert(notifications, { message = message, level = level })
      end
    end,
    post_case = function()
      vim.notify = original_notify
      vim.env.PATH = original_path
      vim.fn.chdir(original_cwd)
      for _, dir in ipairs(tmp_dirs) do
        vim.fn.delete(dir, "rf")
      end
      tmp_dirs = {}
    end,
  },
})

T["outside a repo notifies jj's message and opens nothing"] = function()
  vim.fn.chdir(tmpdir())
  local before = snapshot_layout()

  require("jj").status_open()

  expect.equality(#notifications, 1)
  expect.equality(notifications[1].level, vim.log.levels.ERROR)
  expect.equality(notifications[1].message:find("There is no jj repo", 1, true) ~= nil, true)
  expect.equality(snapshot_layout(), before)
end

T["jj missing notifies jj not found and opens nothing"] = function()
  vim.env.PATH = tmpdir()
  local before = snapshot_layout()

  require("jj").status_open()

  expect.equality(#notifications, 1)
  expect.equality(notifications[1].level, vim.log.levels.ERROR)
  expect.equality(notifications[1].message, "jj not found on $PATH")
  expect.equality(snapshot_layout(), before)
end

return T
