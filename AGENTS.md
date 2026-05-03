Josh's Neovim config. Most changes are Lua config; Python is only for the remote-plugin workspace.

## Commands

- Format Lua: `~/.local/share/nvim/mason/bin/stylua .`
- Validate Neovim startup/config: `nvim --headless -u init.lua +qa`
- Bootstrap/update plugins: `just bootstrap CONFIG_DIR="nvim.new"` / `just update`
- Register Python rplugin: `nvim --headless -u init.lua -c "UpdateRemotePlugins" +qa`
- Install Python deps: `uv sync`
- Lint/fix Python: `uvx ruff check .` / `uvx ruff check . --fix`
- Format Python: `uvx ruff format .`
- Type check Python: `uvx basedpyright . rplugin/python3/spotify`
- Build Python rplugin wheel, if needed: `uvx hatch build -C rplugin/python3/spotify`
- Run tests, if present: `uvx pytest -q`

There is no standalone Lua lint command configured. Use the headless Neovim startup check for agent validation.

## Lua style

- Keep variables and functions local by default.
- Use snake_case for variables and functions.
- Require modules by Lua path, e.g. `require("utils.icons")`.
- Under `lua/plugins`, prefer direct Lazy spec returns.
- Use `local M = {}` / `return M` for reusable modules under `lua/utils`, `lua/pi`, etc., not ordinary plugin spec files.
- For expected failures, use `pcall`/`xpcall`; report user-facing errors with `vim.notify(msg, vim.log.levels.ERROR)`.

## Python style

- Ruff/Black-compatible: 88 columns, double quotes, 4-space indent.
- Imports are absolute and one per line.
- Include `from __future__ import annotations`.
- Annotate functions and vars; prefer precise types over `Any`.
- Naming: snake_case functions/vars, PascalCase classes, UPPER_SNAKE constants.
- No bare `except`; raise specific errors with context; avoid silent `pass`.
