local expect = MiniTest.expect

local STATUS_OUTPUT = "A file.txt\nM other.txt\nD gone.txt\n"

local COMMITS = {
  { bookmarks = { "main*", "dev" }, change_id = "ab", commit_id = "12f", description = "current work" },
  { bookmarks = {}, change_id = "cd", commit_id = "34e", description = "" },
}

local original_status
local original_commits

local T = MiniTest.new_set({
  hooks = {
    pre_case = function()
      local cli = require("jj.cli")
      original_status = cli.status
      cli.status = function() return STATUS_OUTPUT end
      original_commits = cli.commits
      cli.commits = function() return COMMITS end
    end,
    post_case = function()
      require("jj.cli").status = original_status
      require("jj.cli").commits = original_commits
      vim.cmd("silent! %bwipeout!")
    end,
  },
})

local function find_window_by_filetype(filetype)
  for _, candidate in ipairs(vim.api.nvim_list_wins()) do
    local buffer = vim.api.nvim_win_get_buf(candidate)
    if vim.bo[buffer].filetype == filetype then return candidate end
  end
end

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
  local commits_height = #COMMITS
  local total_content = math.floor(vim.o.lines * 0.8) - 2
  expect.equality(config.height, total_content - commits_height - 1)
  expect.equality(config.col, math.floor((vim.o.columns - config.width) / 2))
  expect.equality(config.row, math.floor((vim.o.lines - total_content - 2) / 2))
end

T["shows the status output"] = function()
  local _, buffer = open_window()
  local lines = vim.api.nvim_buf_get_lines(buffer, 0, -1, false)

  expect.equality(lines, { "A file.txt", "M other.txt", "D gone.txt" })
end

T["shows a sticky menu bar below the content"] = function()
  local window = open_window()
  local content_config = vim.api.nvim_win_get_config(window)
  local menu_window
  for _, candidate in ipairs(vim.api.nvim_list_wins()) do
    local buffer = vim.api.nvim_win_get_buf(candidate)
    if vim.bo[buffer].filetype == "jj-menu" then menu_window = candidate end
  end
  local menu_buffer = vim.api.nvim_win_get_buf(menu_window)
  local menu_lines = vim.api.nvim_buf_get_lines(menu_buffer, 0, -1, false)
  local menu_config = vim.api.nvim_win_get_config(menu_window)

  expect.equality(menu_lines[1], string.rep("─", content_config.width))
  expect.equality(menu_lines[2], "r: refresh | s: squash | u: restore")
  local commits_window = find_window_by_filetype("jj-commits")
  local commits_config = vim.api.nvim_win_get_config(commits_window)
  expect.equality(menu_config.row, commits_config.row + 1 + commits_config.height)
  expect.equality(menu_config.focusable, false)
end

T["shows current and parent commits in a bottom pane"] = function()
  open_window()
  local commits_window = find_window_by_filetype("jj-commits")
  local buffer = vim.api.nvim_win_get_buf(commits_window)
  local lines = vim.api.nvim_buf_get_lines(buffer, 0, -1, false)

  expect.equality(lines, {
    "main* dev | ab | 12f | current work",
    "          | cd | 34e | (no description set)",
  })
end

T["marks a bookmarkless working copy with @"] = function()
  require("jj.cli").commits = function()
    return {
      { bookmarks = {}, change_id = "ab", commit_id = "12f", description = "wip" },
      { bookmarks = {}, change_id = "cd", commit_id = "34e", description = "parent" },
    }
  end
  open_window()
  local commits_window = find_window_by_filetype("jj-commits")
  local buffer = vim.api.nvim_win_get_buf(commits_window)
  local lines = vim.api.nvim_buf_get_lines(buffer, 0, -1, false)

  expect.equality(lines, {
    "@ | ab | 12f | wip",
    "  | cd | 34e | parent",
  })
end

T["marks a conflicted commit with a red (C)"] = function()
  require("jj.cli").commits = function()
    return {
      { bookmarks = {}, conflict = false, change_id = "ab", commit_id = "12f", description = "wip" },
      { bookmarks = {}, conflict = true, change_id = "cd", commit_id = "34e", description = "bad" },
    }
  end
  open_window()
  local commits_window = find_window_by_filetype("jj-commits")
  local buffer = vim.api.nvim_win_get_buf(commits_window)
  local lines = vim.api.nvim_buf_get_lines(buffer, 0, -1, false)
  local marks = vim.api.nvim_buf_get_extmarks(buffer, -1, 0, -1, { details = true })
  local conflict_groups = {}
  for _, mark in ipairs(marks) do
    if mark[4].hl_group == "JjConflict" then table.insert(conflict_groups, { mark[2], mark[3] }) end
  end

  expect.equality(lines[1], "@ |     | ab | 12f | wip")
  expect.equality(lines[2], "  | (C) | cd | 34e | bad")
  expect.equality(conflict_groups, { { 1, 4 } })
end

T["caps the commits pane at six rows"] = function()
  local many = {}
  for index = 1, 9 do
    table.insert(many, { bookmarks = {}, change_id = "c" .. index, commit_id = "d" .. index, description = "x" })
  end
  require("jj.cli").commits = function() return many end
  open_window()
  local commits_window = find_window_by_filetype("jj-commits")

  expect.equality(vim.api.nvim_win_get_height(commits_window), 6)
end

T["closing the content window closes the menu"] = function()
  open_window()

  vim.api.nvim_feedkeys(vim.keycode("<Esc>"), "x", false)

  local menu_count = 0
  for _, candidate in ipairs(vim.api.nvim_list_wins()) do
    local buffer = vim.api.nvim_win_get_buf(candidate)
    if vim.bo[buffer].filetype == "jj-menu" then menu_count = menu_count + 1 end
  end
  expect.equality(menu_count, 0)
end

T["highlights lines by modification code"] = function()
  local _, buffer = open_window()
  local namespace = vim.api.nvim_create_namespace("jj")
  local marks = vim.api.nvim_buf_get_extmarks(buffer, namespace, 0, -1, { details = true })
  local groups = {}
  for _, mark in ipairs(marks) do
    table.insert(groups, mark[4].hl_group)
  end

  expect.equality(groups, { "JjAdded", "JjModified", "JjDeleted" })
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

local function is_closed(window, buffer)
  local window_gone = not vim.api.nvim_win_is_valid(window)
  local buffer_gone = not vim.api.nvim_buf_is_valid(buffer)
  return window_gone and buffer_gone
end

T["moving focus to another window closes it and wipes the buffer"] = function()
  local previous = vim.api.nvim_get_current_win()
  local window, buffer = open_window()

  vim.api.nvim_set_current_win(previous)
  local closed = vim.wait(1000, function() return is_closed(window, buffer) end)

  expect.equality(closed, true)
end

T["window command focus change closes it"] = function()
  vim.cmd("split")
  local window, buffer = open_window()

  vim.cmd("wincmd w")
  local closed = vim.wait(1000, function() return is_closed(window, buffer) end)

  expect.equality(closed, true)
end

T["escape leaves no error or leftover window"] = function()
  local windows_before = #vim.api.nvim_list_wins()
  open_window()

  vim.api.nvim_feedkeys(vim.keycode("<Esc>"), "x", false)
  vim.wait(50)

  expect.equality(#vim.api.nvim_list_wins(), windows_before)
  expect.equality(vim.v.errmsg, "")
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

local function count_jj_windows()
  local count = 0
  for _, window in ipairs(vim.api.nvim_list_wins()) do
    local buffer = vim.api.nvim_win_get_buf(window)
    if vim.bo[buffer].filetype == "jj" then count = count + 1 end
  end
  return count
end

T["calling status_open twice leaves one window with current output"] = function()
  local window, buffer = open_window()
  require("jj.cli").status = function() return "new output\n" end

  require("jj").status_open()

  expect.equality(count_jj_windows(), 1)
  expect.equality(vim.api.nvim_get_current_win(), window)
  expect.equality(vim.api.nvim_buf_get_lines(buffer, 0, -1, false), { "new output" })
  expect.equality(vim.bo[buffer].modifiable, false)
end

T["r refreshes the content in place"] = function()
  local window, buffer = open_window()
  require("jj.cli").status = function() return "changed\n" end

  vim.api.nvim_feedkeys("r", "x", false)

  expect.equality(vim.api.nvim_win_is_valid(window), true)
  expect.equality(count_jj_windows(), 1)
  expect.equality(vim.api.nvim_buf_get_lines(buffer, 0, -1, false), { "changed" })
  expect.equality(vim.bo[buffer].modifiable, false)
end

T["refresh failure keeps the window open"] = function()
  local window, buffer = open_window()
  require("jj.cli").status = function() return nil, { kind = "not_a_repo", message = "gone" } end
  local original_notify = vim.notify
  vim.notify = function() end

  vim.api.nvim_feedkeys("r", "x", false)
  vim.notify = original_notify

  expect.equality(vim.api.nvim_win_is_valid(window), true)
  expect.equality(vim.api.nvim_buf_get_lines(buffer, 0, -1, false)[1], "A file.txt")
end

T["registers no user command or default keymap"] = function()
  expect.equality(vim.fn.exists(":JJ"), 0)
  expect.equality(vim.fn.maparg("<leader>jj", "n"), "")
end

return T
