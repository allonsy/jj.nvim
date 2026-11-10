# jj.nvim

A Neovim plugin for working with Jujutsu (jj) repositories from inside the editor, through a Telescope-style floating interface.

## Language

**jj window**:
The centered floating window, titled `jj`, that hosts the plugin's interface. It is a read-only scratch view that closes on `<Esc>`.
_Avoid_: popup, panel, modal

**Status view**:
The content of the jj window showing the output of `jj show -T "" -s @` for the current repo.
_Avoid_: status buffer, status page

**Repo root**:
The top-level directory of the jj repo containing Neovim's working directory, as reported by `jj root`.
_Avoid_: project root, workspace dir

**Commits pane**:
The bottom pane of the jj window listing the current commit (`@`) followed by its immediate parents (`@-`), at most 6 rows before it scrolls. Focus toggles with `<Tab>`.
_Avoid_: log pane, history

**Log view**:
A read-only buffer in the current window showing `jj log`, one commit per line. Opened by `log_open()`.
_Avoid_: log pane, log window

**Change overview**:
A read-only buffer showing one change: its metadata followed by its patches (`jj show`).
_Avoid_: commit page, diff view, show view

**Tree view**:
A read-only buffer listing one directory of the repo as it was at a given change. "Explore" means opening the tree view at the repo root.
_Avoid_: file browser, explorer, netrw

**History view**:
A read-only buffer listing, newest first, the changes at or before a given change that touched one file or directory.
_Avoid_: file log, reverse history

**Blame view**:
A read-only buffer showing a file with, before each line as inline virtual text, the change that introduced it. Opened by `blame_open()`.
_Avoid_: annotate view
