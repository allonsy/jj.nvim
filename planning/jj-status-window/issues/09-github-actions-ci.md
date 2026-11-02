# 09: GitHub Actions workflow to run the tests

**What to build:** Every push and pull request on GitHub runs the plugin's test suite and reports pass or fail. The workflow installs Neovim (the minimum version in the spec, 0.12, and ideally also the latest stable) and jj (0.46 or the minimum version that supports the commands the plugin uses), then runs the same single headless test command a contributor runs locally (ticket 01). A failing test fails the workflow. The tests include ones that run real jj against a temporary repo (ticket 02), so jj must be on `$PATH` in CI, and jj needs a user name and email configured (e.g. via environment variables or `jj config set`) to create commits in those tests.

**Blocked by:** 01 (Test harness), 02 (jj module)

**Status:** ready-for-agent

- [ ] A workflow file under `.github/workflows/` triggers on push and pull request
- [ ] It installs Neovim at the spec's minimum version and a pinned jj version
- [ ] It runs the same command documented in ticket 01 and fails when any test fails
- [ ] The jj module tests (real jj, temporary repo) pass in CI
- [ ] Action versions are pinned to a tag or commit, not a floating branch
- [ ] The workflow can be verified locally or by inspecting a green run once the repo is on GitHub (note which in the ticket when done)

**Context:** Read `planning/jj-status-window/spec.md` (design, layout and decisions) and `GLOSSARY.md` (vocabulary) before starting.
