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
  "change_id.shortest()",
  "commit_id.shortest()",
  "description.first_line()",
}, ' ++ "\\x1f" ++ ') .. ' ++ "\\n"'

local function parse_commit(line)
  local fields = vim.split(line, FIELD_SEPARATOR, { plain = true })
  return {
    bookmarks = vim.split(fields[1], " ", { trimempty = true }),
    change_id = fields[2],
    commit_id = fields[3],
    description = fields[4] or "",
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

return M
