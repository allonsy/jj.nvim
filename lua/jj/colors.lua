local M = {}

local DEFAULTS = {
  STATUS_FILE_ADDED = "#98c379",
  STATUS_FILE_MODIFIED = "#56b6c2",
  STATUS_FILE_DELETED = "#e06c75",
  STATUS_COMMIT_BOOKMARK = "#98c379",
  STATUS_COMMIT_BOOKMARK_AHEAD = "#e06c75",
  STATUS_COMMIT_CHANGE_ID = "#d19ad8",
  STATUS_COMMIT_CID = "#61afef",
}

local GROUP_BY_KEY = {
  STATUS_FILE_ADDED = "JjAdded",
  STATUS_FILE_MODIFIED = "JjModified",
  STATUS_FILE_DELETED = "JjDeleted",
  STATUS_COMMIT_BOOKMARK = "JjBookmarkSynced",
  STATUS_COMMIT_BOOKMARK_AHEAD = "JjBookmarkAhead",
  STATUS_COMMIT_CHANGE_ID = "JjChangeId",
  STATUS_COMMIT_CID = "JjCommitId",
}

local overrides = {}

function M.defaults()
  return vim.deepcopy(DEFAULTS)
end

function M.set(user_colors)
  overrides = vim.deepcopy(user_colors or {})
end

function M.resolve()
  return vim.tbl_extend("force", M.defaults(), overrides)
end

local function highlight_spec(color)
  if type(color) == "table" then return color end
  return { fg = color }
end

function M.apply()
  for key, color in pairs(M.resolve()) do
    local group = GROUP_BY_KEY[key]
    if group then vim.api.nvim_set_hl(0, group, highlight_spec(color)) end
  end
end

return M
