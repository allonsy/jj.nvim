# 04: Notify on errors instead of opening the window

**What to build:** When jj can't be run, `open()` tells the user why and shows no window. If `jj` isn't on `$PATH`, or the cwd isn't inside a jj repo, the user sees a `vim.notify` message at ERROR level (jj's own message for the not-a-repo case, a clear "jj not found" for the missing case).

**Blocked by:** 03 (Open the jj window)

**Status:** ready-for-agent

- [ ] Outside a jj repo, `open()` notifies at ERROR level with jj's message and opens no window
- [ ] With jj missing, `open()` notifies at ERROR level with a "jj not found" message and opens no window
- [ ] No leftover buffer or window remains after an error
- [ ] Tests cover both error paths

**Context:** Read `planning/jj-status-window/spec.md` (design, layout and decisions) and `GLOSSARY.md` (vocabulary) before starting.
