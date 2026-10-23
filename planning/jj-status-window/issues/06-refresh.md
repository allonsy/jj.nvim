# 06: Refresh the status view

**What to build:** The **status view** can be refreshed without reopening. Calling `open()` while the **jj window** is already open refreshes its content and focuses it instead of opening a second window. Pressing `r` in the window refreshes it too. There is no auto-refresh. A refresh keeps the window open even if the underlying data changed.

**Blocked by:** 03 (Open the jj window)

**Status:** ready-for-agent

- [ ] Calling `open()` twice results in exactly one jj window, showing current output
- [ ] After the repo changes, `r` updates the content in place
- [ ] The buffer stays read-only after a refresh
- [ ] Tests cover both the repeated `open()` and the `r` paths

**Context:** Read `planning/jj-status-window/spec.md` (design, layout and decisions) and `GLOSSARY.md` (vocabulary) before starting.
