# 08: README usage docs

**What to build:** The README tells a new user how to install the plugin, bind a key to it and customize it. It shows the keymap example `vim.keymap.set("n", "<leader>jj", require("jj").open)`, lists the `setup` options with their defaults, and briefly describes the behavior (centered window, `<Esc>` to close, `r` to refresh, closes on focus loss, errors via notification). The docs must match what is actually built.

**Blocked by:** 04 (Error handling), 05 (Close on focus loss), 06 (Refresh), 07 (Setup options)

**Status:** ready-for-agent

- [ ] README has an install section and the keymap example
- [ ] Every `setup` option and its default is listed, matching the code
- [ ] Keys and behaviors described match the implementation

**Context:** Read `planning/jj-status-window/spec.md` (design, layout and decisions) and `GLOSSARY.md` (vocabulary) before starting.
