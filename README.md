# jj.nvim
A small nvim plugin for jj operations

## Testing

Tests use [mini.test](https://github.com/echasnovski/mini.nvim), vendored at `tests/lua/mini/test.lua`.
Run all tests headlessly (exits non-zero on failure):

```sh
nvim --headless --noplugin -u tests/minimal_init.lua -c "lua MiniTest.run()"
```

Test files live in `tests/` and are named `test_*.lua`.
