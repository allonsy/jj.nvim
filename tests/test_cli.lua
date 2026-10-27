local expect = MiniTest.expect
local cli = require("jj.cli")

local original_cwd, original_path
local tmp_dirs = {}

local function tmpdir()
  local dir = vim.fn.resolve(vim.fn.tempname())
  vim.fn.mkdir(dir, "p")
  table.insert(tmp_dirs, dir)
  return dir
end

local T = MiniTest.new_set({
  hooks = {
    pre_case = function()
      original_cwd, original_path = vim.fn.getcwd(), vim.env.PATH
    end,
    post_case = function()
      vim.env.PATH = original_path
      vim.fn.chdir(original_cwd)
      for _, dir in ipairs(tmp_dirs) do
        vim.fn.delete(dir, "rf")
      end
      tmp_dirs = {}
    end,
  },
})

T["status from a subdirectory of a repo"] = function()
  local repo = tmpdir()
  vim.system({ "jj", "git", "init" }, { cwd = repo }):wait()
  vim.fn.mkdir(repo .. "/sub/dir", "p")
  vim.fn.writefile({ "hi" }, repo .. "/sub/dir/file.txt")
  vim.fn.chdir(repo .. "/sub/dir")

  local root = cli.root()
  local output, err = cli.status()

  expect.equality(root, repo)
  expect.equality(err, nil)
  expect.equality(output:find("A sub/dir/file.txt", 1, true) ~= nil, true)
  expect.equality(output:find("\27", 1, true), nil)
end

T["status outside a repo"] = function()
  vim.fn.chdir(tmpdir())

  local output, err = cli.status()

  expect.equality(output, nil)
  expect.equality(err.kind, "not_a_repo")
  expect.equality(err.message:find("There is no jj repo", 1, true) ~= nil, true)
end

T["status with jj missing from PATH"] = function()
  vim.env.PATH = tmpdir()

  local output, err = cli.status()

  expect.equality(output, nil)
  expect.equality(err.kind, "jj_not_found")
  expect.equality(err.message, "jj not found on $PATH")
end

return T
