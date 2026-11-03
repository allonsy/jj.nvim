# jj.nvim
A small nvim plugin for jj operations

Requires Neovim 0.12+ and `jj` on your `$PATH`. There are no other dependencies.

## Install

Install with your plugin manager, for example lazy.nvim:

```lua
{ "allonsy/jj.nvim" }
```

The plugin defines no commands and no default keymaps. Bind a key to open the status window:

```lua
vim.keymap.set("n", "<leader>jj", require("jj").status_open)
```

`setup` is optional and only needed to customize colors.

## Status window

`require("jj").status_open()` opens a centered floating window titled `jj`, sized at 80% of the editor. It runs jj from Neovim's cwd and finds the repo root with `jj root`. Calling it again while the window is open refreshes it. If jj is missing or the cwd is not in a repo, an error notification is shown and no window opens.

The window has two panes:

- Top pane: the files changed in the current commit (`@`), one per line, prefixed `A`, `M` or `D`.
- Bottom pane: the current commit (`@`) followed by its immediate parents. It grows to at most 6 rows, then scrolls.

Each commit row has the form:

```
bookmarks | change id | commit id | description
```

- The working copy row shows `@` in the bookmarks column when it has no bookmarks.
- A commit with no description shows `(no description set)`.
- When any listed commit is conflicted, an extra `(C)` column appears before the change id, filled in for conflicted commits.
- Bookmarks that are ahead of their remote (jj marks them with `*`) are colored differently from synced ones.

### Keys

| Key | Action |
| --- | --- |
| `<Tab>` | Switch between the files pane and the commits pane |
| `r` | Refresh |
| `s` | Squash |
| `u` | Restore |
| `d` | Describe (commits pane only) |
| `x` | Abandon (commits pane only, no confirmation) |
| `n` | New commit (`jj new`) |
| `f` | Fork |
| `<Esc>` | Close |

The window also closes when focus moves to anything other than its own panes. After `s`, `u`, `x`, `n` or `f`, the window refreshes. If jj fails, an error notification is shown.

What `s` and `u` do depend on the pane and the line under the cursor:

| Pane | `s` | `u` |
| --- | --- | --- |
| Files | Squash that file from `@` into the parent. With several parents, a picker opens (`<CR>` choose, `<Esc>` or `q` cancel). | Restore that file (`jj restore`), discarding its changes in `@`. |
| Commits | Squash `@` into the commit under the cursor. | Move the changes of the commit under the cursor into `@`. |

Squashes keep the emptied source commit and keep the destination's description.

`n` runs `jj new` and `f` runs `jj new --after 'trunk()' --before @ --no-edit`, which inserts a new empty commit between trunk and `@` without moving to it. Both work in either pane and refresh the window afterwards.

`x` in the commits pane runs `jj abandon` on the commit under the cursor immediately, with no confirmation. Abandoning `@` makes jj move you to a fresh working-copy commit. `x` does nothing in the files pane.

### Describe

`d` in the commits pane opens a floating editor titled `describe <change id>` holding the full description of the commit under the cursor. It is a normal buffer with filetype `jjdescription`. `:wq` saves the message with `jj describe` and refreshes the window. `:q!` cancels and leaves the commit untouched. `d` does nothing in the files pane.

## Configuration

```lua
require("jj").setup({
  colors = {
    STATUS_FILE_ADDED = "#98c379",
    STATUS_FILE_MODIFIED = "#56b6c2",
    STATUS_FILE_DELETED = "#e06c75",
    STATUS_COMMIT_BOOKMARK = "#98c379",
    STATUS_COMMIT_BOOKMARK_AHEAD = "#e06c75",
    STATUS_COMMIT_CONFLICT = "#e06c75",
    STATUS_COMMIT_CHANGE_ID = "#d19ad8",
    STATUS_COMMIT_CID = "#61afef",
  },
})
```

Every key is optional; the values above are the defaults. A value is either a hex string (used as the foreground color) or a table of `nvim_set_hl` attributes such as `{ fg = "#ffffff", bold = true }`.

| Key | Colors | Highlight group |
| --- | --- | --- |
| `STATUS_FILE_ADDED` | Added files | `JjAdded` |
| `STATUS_FILE_MODIFIED` | Modified files | `JjModified` |
| `STATUS_FILE_DELETED` | Deleted files | `JjDeleted` |
| `STATUS_COMMIT_BOOKMARK` | Bookmarks in sync | `JjBookmarkSynced` |
| `STATUS_COMMIT_BOOKMARK_AHEAD` | Bookmarks ahead of remote | `JjBookmarkAhead` |
| `STATUS_COMMIT_CONFLICT` | The `(C)` marker | `JjConflict` |
| `STATUS_COMMIT_CHANGE_ID` | Change id | `JjChangeId` |
| `STATUS_COMMIT_CID` | Commit id | `JjCommitId` |

## Testing

Tests use [mini.test](https://github.com/echasnovski/mini.nvim), vendored at `tests/lua/mini/test.lua`.
Run all tests headlessly (exits non-zero on failure):

```sh
nvim --headless --noplugin -u tests/minimal_init.lua -c "lua MiniTest.run()"
```

Test files live in `tests/` and are named `test_*.lua`.
