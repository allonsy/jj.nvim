local consts = require("jj.consts")
local change = require("jj.change")
local cli = require("jj.cli")
local errors = require("jj.errors")
local view = require("jj.view")

local M = {}

local EMPTY_DESCRIPTION = "(no description set)"

-- Everything of mine that is not on trunk yet, with its descendants.
local MINE_REVSET = "(trunk()..mine()):: | trunk()"
local ALL_REVSET = "::"

local function bookmark_group(bookmark)
  if vim.endswith(bookmark, "*") then return "JjBookmarkAhead" end
  return "JjBookmarkSynced"
end

local function render_row(row, index, spans)
  local entry = row.entry
  if not entry then return row.prefix end
  local line = row.prefix
  local function append(text, group)
    if group then
      table.insert(spans, { row = index - 1, start_col = #line, end_col = #line + #text, group = group })
    end
    line = line .. text .. " "
  end
  append(entry.change_id, "JjChangeId")
  append(entry.commit_id, "JjCommitId")
  if entry.author ~= "" then append(entry.author) end
  append(entry.timestamp)
  for _, bookmark in ipairs(entry.bookmarks) do
    append(bookmark, bookmark_group(bookmark))
  end
  if entry.description == "" then return line .. EMPTY_DESCRIPTION end
  return line .. entry.description
end

function M.render(rows)
  local lines = {}
  local spans = {}
  for index, row in ipairs(rows) do
    table.insert(lines, render_row(row, index, spans))
  end
  return lines, spans
end

-- Shows the log of `revset`, or of jj's default log revset without one.
function M.open(revset)
  local rows, err = cli.log(revset)
  if not rows then
    errors.log_error(err)
    return
  end
  local lines, spans = M.render(rows)
  local function open_change(index)
    local entry = rows[index] and rows[index].entry
    if entry then change.open(entry.revision) end
  end
  view.show({
    name = consts.URI_PREFIX .. "log",
    filetype = "jj-log",
    lines = lines,
    spans = spans,
    keys = {
      ["<CR>"] = open_change,
      m = function() M.open(MINE_REVSET) end,
      a = function() M.open(ALL_REVSET) end,
    },
  })
end

return M
