# 03: Open the jj window showing the status view (tracer bullet)

**What to build:** `require("jj").status_open()` shows the **status view** in the **jj window**: a centered floating window, about 80% of the editor's width and height, with a rounded border and the centered title `jj`. The content comes from the jj module (ticket 02). The buffer is a read-only scratch buffer (wiped on close) with filetype `jj`. `<Esc>` closes the window; `q` is not bound. Users bind `status_open` themselves, e.g. `vim.keymap.set("n", "<leader>jj", require("jj").status_open)`. The plugin ships no user command and no default keymap. If the jj module returns an error, this ticket needs no special handling (see ticket 04).

**Blocked by:** 02 (jj module)

**Status:** ready-for-agent

- [ ] `status_open()` in a jj repo shows a float titled `jj` containing the `jj status` output
- [ ] The float is centered and about 80% of the editor, with a rounded border
- [ ] The buffer is not modifiable, is a scratch buffer and has filetype `jj`; the cursor still moves normally
- [ ] `<Esc>` in normal mode closes the window and wipes the buffer; `q` does nothing special
- [ ] No `:JJ` command and no default keymap are registered
- [ ] Tests (with the jj module stubbed) cover window title, content, buffer options and `<Esc>` close

**Context:** Read `planning/jj-status-window/spec.md` (design, layout and decisions) and `GLOSSARY.md` (vocabulary) before starting.
