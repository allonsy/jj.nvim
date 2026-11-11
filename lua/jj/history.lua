local consts = require("jj.consts")
local cli = require("jj.cli")
local entry_lines = require("jj.entry_lines")
local errors = require("jj.errors")
local file = require("jj.file")
local view = require("jj.view")

local M = {}

local EMPTY_DESCRIPTION = "(no description set)"

local function description_of(entry)
  if entry.description == "" then return EMPTY_DESCRIPTION end
  return entry.description
end

-- Lists the commits at or before `revision` that changed `path`, newest
-- first. `is_dir` says whether `path` is a directory ("" is the repo root).
function M.open(revision, path, is_dir)
  local entries, err = cli.history(revision, path)
  if not entries then
    errors.log_error(err)
    return
  end
  local lines, spans = entry_lines.render(entries, description_of)
  -- change and tree are required lazily: tree requires this module back.
  local function on_entry(action)
    return function(index)
      local entry = entries[index]
      if entry then action(entry) end
    end
  end
  local function open_at(entry)
    if is_dir then
      require("jj.tree").open(entry.revision, path)
    else
      file.open(entry.revision, path)
    end
  end
  view.show({
    name = consts.URI_PREFIX .. "history/" .. view.short(revision) .. "/" .. path,
    filetype = "jj-history",
    lines = lines,
    spans = spans,
    keys = {
      ["<CR>"] = on_entry(open_at),
      c = on_entry(function(entry) require("jj.change").open(entry.revision) end),
      e = on_entry(function(entry) require("jj.tree").open(entry.revision, "") end),
    },
  })
end

return M
