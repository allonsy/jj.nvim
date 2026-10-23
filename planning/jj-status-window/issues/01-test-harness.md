# 01: Test harness

**What to build:** A contributor can run the plugin's tests headlessly with a single documented command, using mini.test. A trivial passing test proves the harness works, so later tickets only add tests.

mini.test is already vendored at `tests/lua/mini/test.lua` (do not move or edit it). The harness must add the `tests` directory to Neovim's `runtimepath` so `require("mini.test")` resolves to that copy and never touches the plugin's own `lua/` directory or the user's installed mini.nvim. Test files live in `tests/` and are named `test_*.lua` (mini.test's default pattern).

**Blocked by:** None (can start immediately)

**Status:** done

- [ ] One command runs all tests headlessly and exits non-zero on failure
- [ ] `require("mini.test")` loads the vendored copy in `tests/lua/mini/test.lua`
- [ ] A trivial `tests/test_*.lua` test passes under that command
- [ ] The command is documented where a contributor will find it (e.g. a short note in the README)

**Context:** Read `planning/jj-status-window/spec.md` (design, layout and decisions) and `GLOSSARY.md` (vocabulary) before starting.
