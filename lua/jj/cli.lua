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
  return run({ "status", "--color=never" }, root)
end

return M
