# 05: Close the jj window on focus loss

**What to build:** Like Telescope, the **jj window** closes when it loses focus (for example the user clicks another window or switches with a window command). `<Esc>` still closes it too. Closing leaves no stale float or buffer behind.

**Blocked by:** 03 (Open the jj window)

**Status:** ready-for-agent

- [x] Moving focus to another window closes the jj window and wipes its buffer
- [x] `<Esc>` still closes the window
- [x] Closing via either route leaves no error or leftover window
- [x] Tests cover close on focus loss

**Context:** Read `planning/jj-status-window/spec.md` (design, layout and decisions) and `GLOSSARY.md` (vocabulary) before starting.
