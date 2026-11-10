local expect = MiniTest.expect

local original_cwd
local tmp_dirs = {}
local repo

local function jj(args)
  local result = vim.system(vim.list_extend({ "jj" }, args), { cwd = repo, text = true }):wait()
  return vim.trim(result.stdout)
end

local function write(path, lines)
  vim.fn.mkdir(vim.fn.fnamemodify(repo .. "/" .. path, ":h"), "p")
  vim.fn.writefile(lines, repo .. "/" .. path)
end

-- Three commits, oldest first: "first" adds a.txt and sub/, "second"
-- edits a.txt, and the working copy "third" edits sub/c.txt.
local function create_repo()
  repo = vim.fn.resolve(vim.fn.tempname())
  vim.fn.mkdir(repo, "p")
  table.insert(tmp_dirs, repo)
  jj({ "git", "init" })
  write("a.txt", { "one" })
  write("sub/c.txt", { "c" })
  write("sub/deep/b.lua", { "return 1" })
  jj({ "commit", "-m", "first" })
  write("a.txt", { "one", "two" })
  jj({ "commit", "-m", "second" })
  write("sub/c.txt", { "c", "more" })
  jj({ "describe", "-m", "third" })
  vim.fn.chdir(repo)
end

local T = MiniTest.new_set({
  hooks = {
    pre_case = function()
      original_cwd = vim.fn.getcwd()
      create_repo()
    end,
    post_case = function()
      vim.fn.chdir(original_cwd)
      vim.cmd("silent! %bwipeout!")
      for _, dir in ipairs(tmp_dirs) do
        vim.fn.delete(dir, "rf")
      end
      tmp_dirs = {}
    end,
  },
})

local function press(keys)
  vim.api.nvim_feedkeys(vim.keycode(keys), "x", false)
end

local function lines()
  return vim.api.nvim_buf_get_lines(0, 0, -1, false)
end

local function name()
  return vim.api.nvim_buf_get_name(0)
end

local function revision(revset)
  return jj({ "log", "-r", revset, "--no-graph", "-T", "commit_id" })
end

local function go_to_line_containing(text)
  for index, line in ipairs(lines()) do
    if line:find(text, 1, true) then
      vim.api.nvim_win_set_cursor(0, { index, 0 })
      return
    end
  end
  error("no line containing " .. text)
end

local function has_line_containing(text)
  for _, line in ipairs(lines()) do
    if line:find(text, 1, true) then return true end
  end
  return false
end

T["log view lists commits newest first in a read-only buffer"] = function()
  require("jj").log_open()

  expect.equality(vim.bo.filetype, "jj-log")
  expect.equality(vim.bo.modifiable, false)
  local shown = lines()
  expect.equality(shown[1]:find("third", 1, true) ~= nil, true)
  expect.equality(shown[2]:find("second", 1, true) ~= nil, true)
  expect.equality(shown[3]:find("first", 1, true) ~= nil, true)
  expect.equality(shown[1]:find("\31", 1, true), nil)
end

T["enter in the log view opens the change overview"] = function()
  require("jj").log_open()
  go_to_line_containing("second")
  press("<CR>")

  expect.equality(vim.bo.filetype, "jj-change")
  expect.equality(vim.bo.modifiable, false)
  expect.equality(lines()[1], "Commit ID: " .. revision("@-"))
  expect.equality(has_line_containing("    second"), true)
  expect.equality(has_line_containing("diff --git a/a.txt b/a.txt"), true)
  expect.equality(has_line_containing("+two"), true)
end

T["m and a in the log view switch to my changes and to all changes"] = function()
  local cli = require("jj.cli")
  local original_log = cli.log
  local revsets = {}
  cli.log = function(revset)
    table.insert(revsets, revset or "default")
    return original_log(revset)
  end
  jj({ "new", "root()", "-m", "elsewhere" })
  jj({ "edit", "description(substring:'third')" })

  require("jj").log_open()
  press("m")
  expect.equality(vim.bo.filetype, "jj-log")
  expect.equality(has_line_containing("third"), true)
  press("a")
  cli.log = original_log

  expect.equality(revsets, { "default", "(trunk()..mine()):: | trunk()", "::" })
  for _, description in ipairs({ "third", "second", "first", "elsewhere" }) do
    expect.equality(has_line_containing(description), true)
  end
  press("<CR>")
  expect.equality(vim.bo.filetype, "jj-change")
end

T["the jumplist goes back from the change overview to the log view"] = function()
  require("jj").log_open()
  go_to_line_containing("second")
  press("<CR>")
  press("<C-o>")

  expect.equality(vim.bo.filetype, "jj-log")
end

T["explore opens the tree as it was at that change"] = function()
  require("jj.change").open(revision("@-"))
  press("e")

  expect.equality(vim.bo.filetype, "jj-tree")
  expect.equality(lines(), { "sub/", "a.txt" })
end

T["the tree view walks into directories and back up"] = function()
  require("jj.tree").open(revision("@"), "")
  press("<CR>")
  expect.equality(lines(), { "../", "deep/", "c.txt" })

  press("j<CR>")
  expect.equality(lines(), { "../", "b.lua" })

  press("-")
  expect.equality(lines(), { "../", "deep/", "c.txt" })
  expect.equality(vim.api.nvim_get_current_line(), "deep/")

  press("gg<CR>")
  expect.equality(lines(), { "sub/", "a.txt" })
end

T["the tree view opens a file as it was at that change"] = function()
  require("jj.tree").open(revision("@--"), "")
  go_to_line_containing("a.txt")
  press("<CR>")

  expect.equality(lines(), { "one" })
  expect.equality(vim.bo.modifiable, false)
  expect.equality(vim.bo.readonly, true)

  require("jj.tree").open(revision("@"), "sub/deep")
  go_to_line_containing("b.lua")
  press("<CR>")
  expect.equality(vim.bo.filetype, "lua")
end

T["history of a file lists only the changes that touched it up to that point"] = function()
  require("jj.tree").open(revision("@"), "")
  go_to_line_containing("a.txt")
  press("h")

  expect.equality(vim.bo.filetype, "jj-history")
  local shown = lines()
  expect.equality(#shown, 2)
  expect.equality(shown[1]:find("second", 1, true) ~= nil, true)
  expect.equality(shown[2]:find("first", 1, true) ~= nil, true)
  local full_id = revision("@-")
  local change_id = jj({ "log", "-r", "@-", "--no-graph", "-T", "change_id.shortest(8)" })
  expect.equality(vim.startswith(shown[1], change_id .. " | " .. full_id:sub(1, 8) .. " | "), true)
  local date = jj({ "log", "-r", "@-", "--no-graph", "-T", 'author.timestamp().format("%Y-%m-%d")' })
  expect.equality(vim.endswith(shown[1], " | " .. date .. " | second"), true)

  require("jj.tree").open(revision("@--"), "")
  go_to_line_containing("a.txt")
  press("h")
  expect.equality(#lines(), 1)
end

T["history of a directory lists the changes below it"] = function()
  require("jj.tree").open(revision("@"), "")
  go_to_line_containing("sub/")
  press("h")

  local shown = lines()
  expect.equality(#shown, 2)
  expect.equality(shown[1]:find("third", 1, true) ~= nil, true)
  expect.equality(shown[2]:find("first", 1, true) ~= nil, true)
end

T["history keys open the file, the change overview and the tree at that change"] = function()
  local history = require("jj.history")
  history.open(revision("@"), "a.txt", false)
  press("j<CR>")
  expect.equality(lines(), { "one" })

  history.open(revision("@"), "a.txt", false)
  press("jc")
  expect.equality(lines()[1], "Commit ID: " .. revision("@--"))

  history.open(revision("@"), "a.txt", false)
  press("je")
  expect.equality(vim.bo.filetype, "jj-tree")
  expect.equality(name():find(revision("@--"):sub(1, 12), 1, true) ~= nil, true)

  history.open(revision("@"), "sub", true)
  press("j<CR>")
  expect.equality(lines(), { "../", "deep/", "c.txt" })
  expect.equality(name():find(revision("@--"):sub(1, 12), 1, true) ~= nil, true)
end

local function blame_prefixes()
  local namespace = vim.api.nvim_get_namespaces()["jj-view"]
  local marks = vim.api.nvim_buf_get_extmarks(0, namespace, 0, -1, { details = true })
  local prefixes = {}
  for _, mark in ipairs(marks) do
    local details = mark[4]
    if details.virt_text then
      local text = ""
      for _, chunk in ipairs(details.virt_text) do
        text = text .. chunk[1]
      end
      expect.equality(details.virt_text_pos, "inline")
      prefixes[mark[2] + 1] = text
    end
  end
  return prefixes
end

T["blame shows the file with each line's change as an inline prefix"] = function()
  vim.cmd.edit(repo .. "/a.txt")
  vim.api.nvim_win_set_cursor(0, { 2, 0 })
  require("jj").blame_open()

  expect.equality(vim.b.jj_blame, true)
  expect.equality(vim.bo.modifiable, false)
  expect.equality(vim.api.nvim_win_get_cursor(0)[1], 2)
  expect.equality(lines(), { "one", "two" })
  local author = jj({ "log", "-r", "@-", "--no-graph", "-T", "author.name()" })
  local function expected(revset)
    local change_id = jj({ "log", "-r", revset, "--no-graph", "-T", "change_id.shortest(8)" })
    local date = jj({ "log", "-r", revset, "--no-graph", "-T", 'author.timestamp().format("%Y-%m-%d")' })
    return table.concat({ change_id, revision(revset):sub(1, 8), author, date, "" }, " | ")
  end
  expect.equality(blame_prefixes(), { expected("@--"), expected("@-") })
end

T["blame keeps the file's own filetype"] = function()
  vim.cmd.edit(repo .. "/sub/deep/b.lua")
  require("jj").blame_open()

  expect.equality(vim.bo.filetype, "lua")
  expect.equality(lines(), { "return 1" })
  expect.equality(#blame_prefixes(), 1)
end

T["blame keys open the file, the change overview and the tree at that change"] = function()
  vim.cmd.edit(repo .. "/a.txt")
  local source = vim.api.nvim_get_current_buf()
  local function blame_line(row)
    vim.api.nvim_set_current_buf(source)
    require("jj").blame_open()
    vim.api.nvim_win_set_cursor(0, { row, 0 })
  end

  blame_line(2)
  press("<CR>")
  expect.equality(lines(), { "one", "two" })
  expect.equality(vim.api.nvim_win_get_cursor(0)[1], 2)
  expect.equality(vim.bo.modifiable, false)

  blame_line(1)
  press("c")
  expect.equality(lines()[1], "Commit ID: " .. revision("@--"))

  blame_line(1)
  press("e")
  expect.equality(vim.bo.filetype, "jj-tree")
  expect.equality(lines(), { "sub/", "a.txt" })
end

T["blame of a file opened from a jj view annotates it at that change"] = function()
  require("jj.file").open(revision("@--"), "a.txt")
  require("jj").blame_open()

  expect.equality(vim.b.jj_blame, true)
  expect.equality(lines(), { "one" })
end

T["blame of a buffer that is not a file reports an error"] = function()
  local messages = {}
  local original_notify = vim.notify
  vim.notify = function(message) table.insert(messages, message) end
  vim.cmd.enew()
  require("jj").blame_open()
  vim.notify = original_notify

  expect.equality(messages, { "jj blame: the current buffer is not a file" })
  expect.equality(vim.bo.filetype, "")
end

T["tree entries list directories before files"] = function()
  local entries = require("jj.tree").entries({ "b.txt", "z/y.txt", "a/x.txt", "a/w/v.txt" }, "")
  local names = vim.tbl_map(function(entry) return entry.name end, entries)
  expect.equality(names, { "a", "z", "b.txt" })

  local nested = require("jj.tree").entries({ "a/x.txt", "a/w/v.txt" }, "a")
  expect.equality(nested, {
    { name = "..", path = "", is_dir = true },
    { name = "w", path = "a/w", is_dir = true },
    { name = "x.txt", path = "a/x.txt", is_dir = false },
  })
end

return T
