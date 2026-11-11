local consts = require("jj.consts")
local change = require("jj.change")
local cli = require("jj.cli")
local entry_lines = require("jj.entry_lines")
local errors = require("jj.errors")
local file = require("jj.file")
local tree = require("jj.tree")
local view = require("jj.view")

local M = {}

local WORKING_COPY = "@"

local FALLBACK_FILETYPE = "jj-blame"

local function real_path(path)
  return vim.uv.fs_realpath(path) or path
end

-- The revision and root-relative path the current buffer shows: a file
-- opened from a jj view keeps its own revision, anything else is a file
-- of the working copy.
local function current_source()
  local opened = vim.b.jj_file
  if opened then return opened end
  local name = vim.api.nvim_buf_get_name(0)
  if name == "" or vim.bo.buftype ~= "" then
    return nil, { message = "jj blame: the current buffer is not a file" }
  end
  local root, err = cli.root()
  if not root then return nil, err end
  local path = vim.fs.relpath(real_path(root), real_path(name))
  if not path then return nil, { message = "jj blame: the current buffer is outside the repo" } end
  return { revision = WORKING_COPY, path = path }
end

function M.open()
  local source, err = current_source()
  if not source then
    errors.log_error(err)
    return
  end
  local annotations, annotate_err = cli.annotate(source.revision, source.path)
  if not annotations then
    errors.log_error(annotate_err)
    return
  end
  -- The buffer holds only the file's content, so its own filetype (and
  -- with it tree-sitter or syntax highlighting) applies; the blame columns
  -- are inline virtual text.
  local lines = vim.tbl_map(function(annotation) return annotation.content end, annotations)
  local function on_line(action)
    return function(index)
      local annotation = annotations[index]
      if annotation then action(annotation) end
    end
  end
  local buffer = view.show({
    name = consts.URI_PREFIX .. "blame/" .. view.short(source.revision) .. "/" .. source.path,
    lines = lines,
    prefixes = entry_lines.prefixes(annotations),
    row = vim.api.nvim_win_get_cursor(0)[1],
    keys = {
      ["<CR>"] = on_line(function(line) file.open(line.revision, source.path, line.line_number) end),
      c = on_line(function(line) change.open(line.revision) end),
      e = on_line(function(line) tree.open(line.revision, "") end),
    },
  })
  vim.b[buffer].jj_file = source
  vim.b[buffer].jj_blame = true
  local filetype = vim.filetype.match({ filename = source.path, buf = buffer }) or FALLBACK_FILETYPE
  if vim.bo[buffer].filetype ~= filetype then vim.bo[buffer].filetype = filetype end
end

return M
