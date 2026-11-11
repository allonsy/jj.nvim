local consts = require("jj.consts")
local cli = require("jj.cli")
local errors = require("jj.errors")
local file = require("jj.file")
local view = require("jj.view")

local M = {}

local PARENT_NAME = ".."

local function parent_of(dir)
  return dir:match("^(.*)/[^/]+$") or ""
end

local function by_kind_then_name(a, b)
  if a.is_dir ~= b.is_dir then return a.is_dir end
  return a.name < b.name
end

-- The immediate children of `dir` ("" for the repo root) given the paths
-- of the files below it: directories first, then files. Below the root,
-- the first entry is `..`.
function M.entries(paths, dir)
  local prefix = ""
  if dir ~= "" then prefix = dir .. "/" end
  local seen = {}
  local entries = {}
  for _, path in ipairs(paths) do
    if vim.startswith(path, prefix) then
      local rest = path:sub(#prefix + 1)
      local name = rest:match("^[^/]+")
      if name and not seen[name] then
        seen[name] = true
        table.insert(entries, { name = name, path = prefix .. name, is_dir = #name < #rest })
      end
    end
  end
  table.sort(entries, by_kind_then_name)
  if dir ~= "" then
    table.insert(entries, 1, { name = PARENT_NAME, path = parent_of(dir), is_dir = true })
  end
  return entries
end

local function render(entries)
  local lines = {}
  local spans = {}
  for index, entry in ipairs(entries) do
    local line = entry.name
    if entry.is_dir then
      line = line .. "/"
      table.insert(spans, { row = index - 1, start_col = 0, end_col = #line, group = "Directory" })
    end
    table.insert(lines, line)
  end
  return lines, spans
end

local function row_of(entries, path)
  for index, entry in ipairs(entries) do
    if entry.path == path and entry.name ~= PARENT_NAME then return index end
  end
end

-- Shows directory `dir` ("" for the repo root) as it was at `revision`.
-- `focus` is the path of the entry to put the cursor on.
function M.open(revision, dir, focus)
  local paths, err = cli.file_list(revision, dir)
  if not paths then
    errors.log_error(err)
    return
  end
  local entries = M.entries(paths, dir)
  local lines, spans = render(entries)
  local function open_entry(index)
    local entry = entries[index]
    if not entry then return end
    if entry.name == PARENT_NAME then
      M.open(revision, entry.path, dir)
    elseif entry.is_dir then
      M.open(revision, entry.path)
    else
      file.open(revision, entry.path)
    end
  end
  local function open_parent()
    if dir ~= "" then M.open(revision, parent_of(dir), dir) end
  end
  local function open_history(index)
    local entry = entries[index]
    if entry then require("jj.history").open(revision, entry.path, entry.is_dir) end
  end
  view.show({
    name = consts.URI_PREFIX .. "tree/" .. view.short(revision) .. "/" .. dir,
    filetype = "jj-tree",
    lines = lines,
    spans = spans,
    row = focus and row_of(entries, focus),
    keys = { ["<CR>"] = open_entry, ["-"] = open_parent, h = open_history },
  })
end

return M
