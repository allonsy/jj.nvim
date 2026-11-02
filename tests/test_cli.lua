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
  expect.equality(output:find("Working copy", 1, true), nil)
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

local function jj(repo, args)
  local result = vim.system(vim.list_extend({ "jj" }, args), { cwd = repo, text = true }):wait()
  return vim.trim(result.stdout)
end

local function repo_with_parent_and_child()
  local repo = tmpdir()
  jj(repo, { "git", "init" })
  vim.fn.writefile({ "base" }, repo .. "/keep.txt")
  jj(repo, { "describe", "-m", "parent" })
  jj(repo, { "new", "-m", "child" })
  vim.fn.writefile({ "edit" }, repo .. "/keep.txt")
  vim.fn.writefile({ "new" }, repo .. "/my file.txt")
  vim.fn.chdir(repo)
  return repo
end

T["squash_file moves one file into the target"] = function()
  local repo = repo_with_parent_and_child()
  local parent_id = jj(repo, { "log", "-r", "@-", "--no-graph", "-T", "change_id.shortest()" })

  local ok, err = cli.squash_file("my file.txt", parent_id)

  expect.equality(err, nil)
  expect.equality(ok ~= nil, true)
  local child_files = jj(repo, { "diff", "-r", "@", "-s" })
  expect.equality(child_files, "M keep.txt")
  local parent_files = jj(repo, { "diff", "-r", "@-", "-s" })
  expect.equality(parent_files:find("my file.txt", 1, true) ~= nil, true)
end

T["squash_commit squashes everything into the target"] = function()
  local repo = repo_with_parent_and_child()
  local parent_id = jj(repo, { "log", "-r", "@-", "--no-graph", "-T", "change_id.shortest()" })

  local ok = cli.squash_commit(parent_id)

  expect.equality(ok ~= nil, true)
  expect.equality(jj(repo, { "diff", "-r", "@", "-s" }), "")
  local working_copy_description = jj(repo, { "log", "-r", "@", "--no-graph", "-T", "description.first_line()" })
  expect.equality(working_copy_description, "child")
end

T["restore_file discards one file's changes"] = function()
  local repo = repo_with_parent_and_child()

  local ok = cli.restore_file("keep.txt")

  expect.equality(ok ~= nil, true)
  expect.equality(jj(repo, { "diff", "-r", "@", "-s" }), "A my file.txt")
end

T["unsquash_commit pulls a commit's changes into the working copy"] = function()
  local repo = repo_with_parent_and_child()
  local parent_id = jj(repo, { "log", "-r", "@-", "--no-graph", "-T", "change_id.shortest()" })

  local ok, err = cli.unsquash_commit(parent_id)

  expect.equality(err, nil)
  expect.equality(ok ~= nil, true)
  local files = jj(repo, { "diff", "-r", "@", "-s" })
  expect.equality(files:find("keep.txt", 1, true) ~= nil, true)
end

T["commits reports whether a commit is conflicted"] = function()
  local repo = repo_with_parent_and_child()
  jj(repo, { "new", "@-", "-m", "side" })
  vim.fn.writefile({ "side" }, repo .. "/keep.txt")
  jj(repo, { "rebase", "-r", "@", "-d", "description(substring:\"child\")" })

  local commits = cli.commits()

  expect.equality(commits[1].conflict, true)
  expect.equality(commits[2].conflict, false)
end

T["a failing operation returns an error"] = function()
  repo_with_parent_and_child()

  local ok, err = cli.squash_commit("zzzznonexistent")

  expect.equality(ok, nil)
  expect.equality(type(err.message), "string")
end

return T
