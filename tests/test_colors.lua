local expect = MiniTest.expect

local function foreground_of(group)
  local spec = vim.api.nvim_get_hl(0, { name = group })
  return spec.fg
end

local T = MiniTest.new_set({
  hooks = {
    post_case = function() require("jj").setup() end,
  },
})

T["defaults apply without setup"] = function()
  require("jj").setup()
  require("jj.colors").apply()

  expect.equality(foreground_of("JjAdded"), 0x98c379)
  expect.equality(foreground_of("JjCommitId"), 0x61afef)
end

T["setup overrides only the given keys"] = function()
  require("jj").setup({ colors = { STATUS_FILE_ADDED = "#112233" } })
  require("jj.colors").apply()

  expect.equality(foreground_of("JjAdded"), 0x112233)
  expect.equality(foreground_of("JjModified"), 0x56b6c2)
end

T["setup overrides every key"] = function()
  local all = {}
  for key in pairs(require("jj.colors").defaults()) do
    all[key] = "#010203"
  end
  require("jj").setup({ colors = all })
  require("jj.colors").apply()

  expect.equality(foreground_of("JjBookmarkSynced"), 0x010203)
  expect.equality(foreground_of("JjBookmarkAhead"), 0x010203)
  expect.equality(foreground_of("JjChangeId"), 0x010203)
  expect.equality(foreground_of("JjDeleted"), 0x010203)
end

T["a highlight table is passed through"] = function()
  require("jj").setup({ colors = { STATUS_COMMIT_CID = { fg = "#0a0b0c", bold = true } } })
  require("jj.colors").apply()

  expect.equality(foreground_of("JjCommitId"), 0x0a0b0c)
end

T["calling setup again replaces earlier choices"] = function()
  require("jj").setup({ colors = { STATUS_FILE_ADDED = "#112233" } })
  require("jj").setup({ colors = { STATUS_FILE_MODIFIED = "#445566" } })
  require("jj.colors").apply()

  expect.equality(foreground_of("JjAdded"), 0x98c379)
  expect.equality(foreground_of("JjModified"), 0x445566)
end

return T
