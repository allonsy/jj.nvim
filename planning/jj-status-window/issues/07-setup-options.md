# 07: Optional `setup(opts)` for window options

**What to build:** `require("jj").setup(opts)` lets users customize the **jj window**. It is optional: `status_open()` works with defaults if `setup` is never called. For now `opts` covers `width` and `height` (fractions of the editor, default about 0.8) and `border` (default rounded). Options given to `setup` are merged over the defaults, and the window honors them. Calling `setup` again replaces earlier choices.

**Blocked by:** 03 (Open the jj window)

**Status:** ready-for-agent

- [ ] `status_open()` without `setup()` behaves as in ticket 03
- [ ] `setup({ width = 0.5 })` changes the window width and leaves the other options at their defaults
- [ ] `border` is passed through to the window
- [ ] Tests cover defaults, partial override and full override

**Context:** Read `planning/jj-status-window/spec.md` (design, layout and decisions) and `GLOSSARY.md` (vocabulary) before starting.
