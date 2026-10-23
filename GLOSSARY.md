# jj.nvim

A Neovim plugin for working with Jujutsu (jj) repositories from inside the editor, through a Telescope-style floating interface.

## Language

**jj window**:
The centered floating window, titled `jj`, that hosts the plugin's interface. It is a read-only scratch view that closes on `<Esc>`.
_Avoid_: popup, panel, modal

**Status view**:
The content of the jj window showing the output of `jj status` for the current repo.
_Avoid_: status buffer, status page

**Repo root**:
The top-level directory of the jj repo containing Neovim's working directory, as reported by `jj root`.
_Avoid_: project root, workspace dir
