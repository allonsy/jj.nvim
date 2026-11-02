local M = {}

local DELIMITER = " | "
local EMPTY_DESCRIPTION = "(no description set)"
local WORKING_COPY_MARKER = "@"

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
  local lines = {}
  local spans = {}
  for index, commit in ipairs(commits) do
    local row = index - 1
    local bookmarks = pad(bookmarks_text(commit), bookmarks_width)
    local change_start = #bookmarks + #DELIMITER
    local commit_start = change_start + #commit.change_id + #DELIMITER
    local line = table.concat({
      bookmarks,
      commit.change_id,
      commit.commit_id,
      description_of(commit),
    }, DELIMITER)
    table.insert(lines, line)
    vim.list_extend(spans, bookmark_highlights(commit, row))
    table.insert(spans, field_highlight(row, change_start, commit.change_id, "JjChangeId"))
    table.insert(spans, field_highlight(row, commit_start, commit.commit_id, "JjCommitId"))
  end
  return lines, spans
end

return M
