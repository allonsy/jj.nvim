# 02: jj module (find repo root, get status)

**What to build:** A Lua module, with no UI, that runs jj on behalf of the plugin. Given Neovim's cwd, it finds the **repo root** with `jj root`, then returns the output of `jj status --color=never` run from that root, so paths are relative to the root. This module is the only place the plugin runs jj, and it is the seam tests use to stub jj. Failures (jj not on `$PATH`, cwd not inside a repo) are returned as distinguishable errors with a human-readable message, not thrown and not shown to the user here.

**Blocked by:** 01 (Test harness)

**Status:** ready-for-agent

- [ ] From a subdirectory of a jj repo, the module returns the status output computed from the repo root
- [ ] Output contains no color escape codes
- [ ] Outside a repo, it returns an error carrying jj's stderr
- [ ] With jj missing from `$PATH`, it returns a "jj not found" error
- [ ] Tests cover success, not-a-repo and jj-missing, using a temporary jj repo and a stubbed jj for the missing case

**Context:** Read `planning/jj-status-window/spec.md` (design, layout and decisions) and `GLOSSARY.md` (vocabulary) before starting.
