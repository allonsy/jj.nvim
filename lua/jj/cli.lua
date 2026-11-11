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

local function content_lines(out)
  local lines = vim.split(out, "\n", { plain = true })
  if lines[#lines] == "" then table.remove(lines) end
  return lines
end

local function path_fileset(path)
  local escaped = path:gsub("\\", "\\\\"):gsub('"', '\\"')
  return 'root:"' .. escaped .. '"'
end

local DATE_LENGTH = #"2026-01-31"

local AUTHOR = "coalesce(author.name(), author.email())"

local ENTRY_TEMPLATE = table.concat({
  "commit_id",
  "change_id.shortest(8)",
  "commit_id.shortest(8)",
  AUTHOR,
  'author.timestamp().format("%Y-%m-%d %H:%M")',
  "bookmarks",
  "description.first_line()",
}, ' ++ "\\x1f" ++ ') .. ' ++ "\\n"'

-- `revision` is the full commit id, used to address the commit in later jj
-- calls. `change_id` and `commit_id` are the short forms meant for display.
local function parse_entry(text)
  local fields = vim.split(text, FIELD_SEPARATOR, { plain = true })
  return {
    revision = fields[1],
    change_id = fields[2],
    commit_id = fields[3],
    author = fields[4],
    timestamp = fields[5],
    date = fields[5]:sub(1, DATE_LENGTH),
    bookmarks = vim.split(fields[6], " ", { trimempty = true }),
    description = fields[7] or "",
  }
end

-- One row per line of `jj log` output. Every row has the graph `prefix`
-- drawn before it; rows that describe a commit also have an `entry`.
-- Without a `revset`, jj's configured default log revset applies.
function M.log(revset)
  local template = '"\\x1f" ++ ' .. ENTRY_TEMPLATE
  local args = { "log", "--color=never", "-T", template }
  if revset then vim.list_extend(args, { "-r", revset }) end
  local out, err = run_in_root(args)
  if not out then return nil, err end
  local rows = {}
  for _, line in ipairs(content_lines(out)) do
    local prefix, rest = line:match("^(.-)" .. FIELD_SEPARATOR .. "(.*)$")
    local row = { prefix = prefix or line }
    if rest then row.entry = parse_entry(rest) end
    table.insert(rows, row)
  end
  return rows
end

function M.show(revision)
  local out, err = run_in_root({ "show", "-r", revision, "--git", "--color=never" })
  if not out then return nil, err end
  return content_lines(out)
end

-- Root-relative paths of every file under `dir` ("" for the repo root).
function M.file_list(revision, dir)
  local args = { "file", "list", "-r", revision }
  if dir ~= "" then table.insert(args, path_fileset(dir)) end
  local out, err = run_in_root(args)
  if not out then return nil, err end
  return content_lines(out)
end

function M.file_show(revision, path)
  local out, err = run_in_root({ "file", "show", "-r", revision, file_fileset(path) })
  if not out then return nil, err end
  return content_lines(out)
end

-- Commits at or before `revision` that changed `path` (a file or a
-- directory, "" for the repo root), newest first.
function M.history(revision, path)
  local args = { "log", "--no-graph", "--color=never", "-r", "::" .. revision, "-T", ENTRY_TEMPLATE }
  if path ~= "" then table.insert(args, path_fileset(path)) end
  local out, err = run_in_root(args)
  if not out then return nil, err end
  local entries = {}
  for _, line in ipairs(content_lines(out)) do
    table.insert(entries, parse_entry(line))
  end
  return entries
end

local ANNOTATE_FIELD_COUNT = 7

local ANNOTATE_TEMPLATE = table.concat({
  "commit.commit_id()",
  "commit.change_id().shortest(8)",
  "commit.commit_id().shortest(8)",
  "coalesce(commit.author().name(), commit.author().email())",
  'commit.author().timestamp().format("%Y-%m-%d")',
  "original_line_number",
  "content",
}, ' ++ "\\x1f" ++ ')

-- One item per line of `path` at `revision`, naming the commit that
-- introduced the line and the line's number in that commit.
function M.annotate(revision, path)
  local args = { "file", "annotate", "-r", revision, "-T", ANNOTATE_TEMPLATE, path }
  local out, err = run_in_root(args)
  if not out then return nil, err end
  local annotations = {}
  for _, line in ipairs(content_lines(out)) do
    local fields = vim.split(line, FIELD_SEPARATOR, { plain = true })
    local content = table.concat(vim.list_slice(fields, ANNOTATE_FIELD_COUNT), FIELD_SEPARATOR)
    table.insert(annotations, {
      revision = fields[1],
      change_id = fields[2],
      commit_id = fields[3],
      author = fields[4],
      date = fields[5],
      line_number = tonumber(fields[6]),
      content = content,
    })
  end
  return annotations
end

return M
