# Spec: jj status window

Read `GLOSSARY.md` first and use its terms (**jj window**, **status view**, **repo root**).

## Goal

A Neovim plugin for Jujutsu (jj). Users bind a key to a Lua function that pops up a Telescope-style floating window titled `jj` showing `jj status`. This is the first feature; more will follow (selecting lines to act on from a menu, other contexts and panes), so keep the design extensible but build only what is listed here.

## Environment

- Neovim 0.12+ (floating-window titles, `vim.system`).
- jj 0.46 (`jj root`, `jj status --color=never`).
- Pure Lua, no runtime dependencies. Tests use mini.test, vendored at `tests/lua/mini/test.lua` (dev-only; `tests/` is added to `runtimepath` by the test setup, never `lua/`).

## Decisions

- **API:** `require("jj").status_open()` is the only entry point. There is no user command (`:JJ`) and no default keymap, so there is no `plugin/` directory. Users write e.g. `vim.keymap.set("n", "<leader>jj", require("jj").status_open)`.
- **Config:** `require("jj").setup(opts)` is optional. Options: `width`, `height` (fractions of the editor, default 0.8) and `border` (default rounded).
- **Content:** run `jj root` from Neovim's cwd (not the current file's directory), then `jj status --color=never` with the repo root as the working directory, so paths are relative to the root. One-shot snapshot, no auto-refresh.
- **Window:** a single pane, centered, titled `jj` (centered title). Read-only scratch buffer (`nofile`, wiped on close, `nomodifiable`), filetype `jj`. Read-only does not block cursor movement or buffer-local keymaps, which later features will use for line selection.
- **Closing:** `<Esc>` closes it and so does losing focus (`WinLeave`), matching Telescope. `q` is deliberately not bound.
- **Refresh:** `r` in the window, or calling `status_open()` again while it is open, refreshes and focuses the existing window.
- **Errors:** jj missing from `$PATH` or cwd not in a repo gives a `vim.notify` at ERROR level and no window.

## Layout

```
lua/jj/init.lua    setup() and status_open()
lua/jj/window.lua  the jj window (floating window and buffer)
lua/jj/cli.lua     the only place jj is run; the seam tests stub
```

`cli.lua` returns errors as values (not-a-repo, jj-not-found); turning them into notifications is the caller's job.

## Tickets

See `issues/`. Each ticket's "Blocked by" lists what must land first; start with any ticket whose blockers are all done.
