local M = {}

local DELIMITER = " | "

local function column_width(entries, field)
  local width = 0
  for _, entry in ipairs(entries) do
    width = math.max(width, vim.fn.strdisplaywidth(entry[field]))
  end
  return width
end

local function pad(text, width)
  return text .. string.rep(" ", width - vim.fn.strdisplaywidth(text))
end

-- One prefix per entry: `change id | commit id | author | date | ` as a
-- list of { text, highlight group } chunks, with the columns aligned
-- across entries.
function M.prefixes(entries)
  local change_width = column_width(entries, "change_id")
  local commit_width = column_width(entries, "commit_id")
  local author_width = column_width(entries, "author")
  local prefixes = {}
  for _, entry in ipairs(entries) do
    table.insert(prefixes, {
      { pad(entry.change_id, change_width), "JjChangeId" },
      { DELIMITER },
      { pad(entry.commit_id, commit_width), "JjCommitId" },
      { DELIMITER },
      { pad(entry.author, author_width) },
      { DELIMITER },
      { entry.date },
      { DELIMITER },
    })
  end
  return prefixes
end

-- Renders one line per entry: its prefix followed by `text_of(entry)`.
-- Returns the lines and the highlight spans for the ids.
function M.render(entries, text_of)
  local lines = {}
  local spans = {}
  for index, prefix in ipairs(M.prefixes(entries)) do
    local line = ""
    for _, chunk in ipairs(prefix) do
      local text, group = chunk[1], chunk[2]
      if group then
        table.insert(spans, { row = index - 1, start_col = #line, end_col = #line + #text, group = group })
      end
      line = line .. text
    end
    table.insert(lines, line .. text_of(entries[index]))
  end
  return lines, spans
end

return M
