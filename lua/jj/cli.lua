local M = {}

local function run(args, cwd)
  local ok, job = pcall(vim.system, vim.list_extend({ "jj" }, args), { cwd = cwd, text = true })
  if not ok then return nil, { kind = "jj_not_found", message = "jj not found on $PATH" } end
  local result = job:wait()
  if result.code ~= 0 then
    local message = vim.trim(result.stderr or "")
    if message == "" then message = ("jj exited with code %d"):format(result.code) end
    return nil, { kind = "not_a_repo", message = message }
  end
  return result.stdout
end

function M.root()
  local out, err = run({ "root" }, vim.fn.getcwd())
  if not out then return nil, err end
  return vim.trim(out)
end

function M.status()
  local root, err = M.root()
  if not root then return nil, err end
  return run({ "show", "@", "-T", "", "-s", "--color=never" }, root)
end

local FIELD_SEPARATOR = "\31"

local COMMITS_TEMPLATE = table.concat({
  "bookmarks",
  "conflict",
  "change_id.shortest()",
  "commit_id.shortest()",
  "description.first_line()",
}, ' ++ "\\x1f" ++ ') .. ' ++ "\\n"'

local function parse_commit(line)
  local fields = vim.split(line, FIELD_SEPARATOR, { plain = true })
  return {
    bookmarks = vim.split(fields[1], " ", { trimempty = true }),
    conflict = fields[2] == "true",
    change_id = fields[3],
    commit_id = fields[4],
    description = fields[5] or "",
  }
end

function M.commits()
  local root, err = M.root()
  if not root then return nil, err end
  local args = { "log", "-r", "@ | @-", "--no-graph", "--color=never", "-T", COMMITS_TEMPLATE }
  local out, run_err = run(args, root)
  if not out then return nil, run_err end
  local commits = {}
  for _, line in ipairs(vim.split(out, "\n", { trimempty = true })) do
    table.insert(commits, parse_commit(line))
  end
  return commits
end

local function run_in_root(args)
  local root, err = M.root()
  if not root then return nil, err end
  return run(args, root)
end

local function file_fileset(path)
  local escaped = path:gsub("\\", "\\\\"):gsub('"', '\\"')
  return 'root-file:"' .. escaped .. '"'
end

local function squash_args(extra)
  local args = { "squash", "--keep-emptied", "--use-destination-message" }
  return vim.list_extend(args, extra)
end

function M.squash_file(path, change_id)
  local args = squash_args({ "--into", change_id, file_fileset(path) })
  return run_in_root(args)
end

function M.squash_commit(change_id)
  local args = squash_args({ "--into", change_id })
  return run_in_root(args)
end

function M.restore_file(path)
  return run_in_root({ "restore", file_fileset(path) })
end

function M.unsquash_commit(change_id)
  local args = squash_args({ "--from", change_id, "--into", "@" })
  return run_in_root(args)
end

function M.abandon(change_id)
  return run_in_root({ "abandon", change_id })
end

function M.new()
  return run_in_root({ "new" })
end

function M.fork()
  return run_in_root({ "new", "--after", "trunk()", "--before", "@", "--no-edit" })
end

function M.get_description(change_id)
  local args = { "log", "-r", change_id, "--no-graph", "--color=never", "-T", "description" }
  return run_in_root(args)
end

function M.describe(change_id, message)
  return run_in_root({ "describe", "-r", change_id, "-m", message })
end

return M
