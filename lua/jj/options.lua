local M = {}

local DEFAULTS = {
  width = 0.8,
  height = 0.8,
  border = "rounded",
}

local BORDER_STYLES = {
  rounded = { "╭", "─", "╮", "│", "╯", "─", "╰", "│" },
  single = { "┌", "─", "┐", "│", "┘", "─", "└", "│" },
  double = { "╔", "═", "╗", "║", "╝", "═", "╚", "║" },
  solid = { " ", " ", " ", " ", " ", " ", " ", " " },
}

local JUNCTIONS = {
  rounded = { "├", "┤" },
  single = { "├", "┤" },
  double = { "╠", "╣" },
  solid = { " ", " " },
}

local EDGE_COUNT = 8

local overrides = {}

function M.defaults()
  return vim.deepcopy(DEFAULTS)
end

function M.set(user_options)
  local given = user_options or {}
  overrides = vim.deepcopy(given)
end

function M.resolve()
  local defaults = M.defaults()
  return vim.tbl_extend("force", defaults, overrides)
end

local function edge_character(edge)
  if type(edge) == "table" then return edge[1] end
  return edge
end

local function characters_from_table(border)
  if #border ~= EDGE_COUNT then return nil end
  local characters = {}
  for index, edge in ipairs(border) do
    characters[index] = edge_character(edge)
  end
  return characters
end

local function characters_for(border)
  if type(border) == "table" then
    local characters = characters_from_table(border)
    if characters then return characters, { characters[8], characters[4] } end
  end
  local name = border
  if not BORDER_STYLES[name] then name = DEFAULTS.border end
  return BORDER_STYLES[name], JUNCTIONS[name]
end

function M.borders()
  local resolved = M.resolve()
  local c, junctions = characters_for(resolved.border)
  return {
    content = { c[1], c[2], c[3], c[4], "", "", "", c[8] },
    commits = { junctions[1], c[2], junctions[2], c[4], c[5], c[6], c[7], c[8] },
  }
end

return M
