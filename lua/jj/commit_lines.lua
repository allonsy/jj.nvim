local M = {}

local DELIMITER = " | "
local EMPTY_DESCRIPTION = "(no description set)"
local WORKING_COPY_MARKER = "@"
local CONFLICT_MARKER = "(C)"

local function bookmark_group(bookmark)
  if vim.endswith(bookmark, "*") then return "JjBookmarkAhead" end
  return "JjBookmarkSynced"
end

local function bookmarks_text(commit)
  return table.concat(commit.bookmarks, " ")
end

local function widest_commit_length(commits, measure)
  local width = 0
  for _, commit in ipairs(commits) do
    width = math.max(width, #measure(commit))
  end
  return width
end

local function pad(text, width)
  return text .. string.rep(" ", width - #text)
end

local function bookmark_highlights(commit, row)
  local spans = {}
  local column = 0
  for _, bookmark in ipairs(commit.bookmarks) do
    table.insert(spans, {
      row = row,
      start_col = column,
      end_col = column + #bookmark,
      group = bookmark_group(bookmark),
    })
    column = column + #bookmark + 1
  end
  return spans
end

local function field_highlight(row, start_col, text, group)
  return { row = row, start_col = start_col, end_col = start_col + #text, group = group }
end

local function conflict_text(commit)
  if commit.conflict then return CONFLICT_MARKER end
  return string.rep(" ", #CONFLICT_MARKER)
end

local function any_conflicted(commits)
  for _, commit in ipairs(commits) do
    if commit.conflict then return true end
  end
  return false
end

local function description_of(commit)
  if commit.description == "" then return EMPTY_DESCRIPTION end
  return commit.description
end

local function mark_working_copy(commits)
  local marked = vim.deepcopy(commits)
  local working_copy = marked[1]
  if working_copy and #working_copy.bookmarks == 0 then
    working_copy.bookmarks = { WORKING_COPY_MARKER }
  end
  return marked
end

function M.render_commits(commits)
  commits = mark_working_copy(commits)
  local bookmarks_width = widest_commit_length(commits, bookmarks_text)
  local show_conflict_column = any_conflicted(commits)
  local conflict_width = 0
  if show_conflict_column then conflict_width = #CONFLICT_MARKER + #DELIMITER end
  local lines = {}
  local spans = {}
  for index, commit in ipairs(commits) do
    local row = index - 1
    local bookmarks = pad(bookmarks_text(commit), bookmarks_width)
    local conflict_start = #bookmarks + #DELIMITER
    local change_start = conflict_start + conflict_width
    local commit_start = change_start + #commit.change_id + #DELIMITER
    local fields = { bookmarks }
    if show_conflict_column then table.insert(fields, conflict_text(commit)) end
    vim.list_extend(fields, { commit.change_id, commit.commit_id, description_of(commit) })
    table.insert(lines, table.concat(fields, DELIMITER))
    vim.list_extend(spans, bookmark_highlights(commit, row))
    if commit.conflict then
      table.insert(spans, field_highlight(row, conflict_start, CONFLICT_MARKER, "JjConflict"))
    end
    table.insert(spans, field_highlight(row, change_start, commit.change_id, "JjChangeId"))
    table.insert(spans, field_highlight(row, commit_start, commit.commit_id, "JjCommitId"))
  end
  return lines, spans
end

function M.render_choices(commits)
  local labels = {}
  for _, commit in ipairs(commits) do
    local bookmarks = table.concat(commit.bookmarks, " ")
    table.insert(labels, bookmarks .. " | " .. commit.change_id)
  end
  return labels
end

return M
