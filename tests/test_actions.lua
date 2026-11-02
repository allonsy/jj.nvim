local expect = MiniTest.expect

local COMMITS = {
  { bookmarks = {}, change_id = "wc", commit_id = "111", description = "work" },
  { bookmarks = { "main" }, change_id = "pa", commit_id = "222", description = "first parent" },
  { bookmarks = {}, change_id = "pb", commit_id = "333", description = "second parent" },
}

local calls
local original = {}

local function stub(name, fn)
  local cli = require("jj.cli")
  original[name] = cli[name]
  cli[name] = fn
end

local T = MiniTest.new_set({
  hooks = {
    pre_case = function()
      calls = {}
      stub("status", function() return "M a.txt\nA b.txt\n" end)
      stub("commits", function() return COMMITS end)
      stub("squash_file", function(path, id) table.insert(calls, { "squash_file", path, id }); return "" end)
      stub("squash_commit", function(id) table.insert(calls, { "squash_commit", id }); return "" end)
      stub("restore_file", function(path) table.insert(calls, { "restore_file", path }); return "" end)
      stub("unsquash_commit", function(id) table.insert(calls, { "unsquash_commit", id }); return "" end)
    end,
    post_case = function()
      local cli = require("jj.cli")
      for name, fn in pairs(original) do
        cli[name] = fn
      end
      vim.cmd("silent! %bwipeout!")
    end,
  },
})

local function press(keys)
  vim.api.nvim_feedkeys(vim.keycode(keys), "x", false)
end

local function window_with_filetype(filetype)
  for _, candidate in ipairs(vim.api.nvim_list_wins()) do
    local buffer = vim.api.nvim_win_get_buf(candidate)
    if vim.bo[buffer].filetype == filetype then return candidate end
  end
end

local function open_on_file_line(line)
  require("jj").status_open()
  vim.api.nvim_win_set_cursor(0, { line, 0 })
end

local function open_on_commit_row(row)
  require("jj").status_open()
  press("<Tab>")
  vim.api.nvim_win_set_cursor(0, { row, 0 })
end

T["restore on a file restores that file"] = function()
  open_on_file_line(2)
  press("u")
  expect.equality(calls, { { "restore_file", "b.txt" } })
end

T["restore on a commit unsquashes it into the working copy"] = function()
  open_on_commit_row(2)
  press("u")
  expect.equality(calls, { { "unsquash_commit", "pa" } })
end

T["squash on a commit squashes it"] = function()
  open_on_commit_row(3)
  press("s")
  expect.equality(calls, { { "squash_commit", "pb" } })
end

T["squash on a file with several parents asks which parent"] = function()
  open_on_file_line(1)
  press("s")

  local popup = window_with_filetype("jj-select")
  local buffer = vim.api.nvim_win_get_buf(popup)
  local lines = vim.api.nvim_buf_get_lines(buffer, 0, -1, false)
  expect.equality(lines, { "main | pa", " | pb" })
  expect.equality(calls, {})

  press("j")
  press("<CR>")

  expect.equality(calls, { { "squash_file", "a.txt", "pb" } })
  expect.equality(window_with_filetype("jj-select"), nil)
end

T["cancelling the parent choice squashes nothing"] = function()
  open_on_file_line(1)
  press("s")
  press("<Esc>")

  expect.equality(calls, {})
  expect.equality(window_with_filetype("jj-select"), nil)
  expect.equality(window_with_filetype("jj") ~= nil, true)
end

T["squash on a file with one parent skips the choice"] = function()
  require("jj.cli").commits = function() return { COMMITS[1], COMMITS[2] } end
  open_on_file_line(1)
  press("s")

  expect.equality(calls, { { "squash_file", "a.txt", "pa" } })
  expect.equality(window_with_filetype("jj-select"), nil)
end

T["the window refreshes after an operation"] = function()
  open_on_file_line(1)
  local refreshes = 0
  require("jj.cli").status = function()
    refreshes = refreshes + 1
    return "M a.txt\n"
  end
  press("u")

  expect.equality(refreshes, 1)
end

return T
