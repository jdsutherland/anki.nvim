# Agent Instructions for anki.nvim

Guidelines for AI agents working on this Neovim plugin codebase.

## Project Overview

anki.nvim is a Neovim plugin for creating and managing Anki flashcards from the editor. It communicates with Anki via the AnkiConnect addon over HTTP using `plenary.curl`.

**Dependencies:** `plenary.nvim` (required), `nvim-notify` (optional, falls back to `vim.notify`), AnkiConnect addon (external).

**Directory layout:**
- `lua/anki/` — Plugin source (init.lua entry point, config, api, ankiconnect, editor, notification, state, utils)
- `lua/anki/classes/` — Class modules (EditorContext, Field, Note, UI)
- `lua/anki/ui/` — UI operations (windows, operations, deck_ops, note_ops, profile_ops, help)
- `tests/plenary/` — Test specs (classes_spec, config_spec, notification_spec, utils_spec)
- `doc/` — Vim help docs and tags file (generated via `scripts/doc-gen.sh`)

## Build, Lint, and Test

- **Build:** No build step. Pure Lua Neovim plugin.
- **Format:** `stylua` via `pre-commit.sh` (auto-installs as git hook). Run manually: `stylua lua/`
- **Lint:** No linter configured.

### Test Commands

```bash
# Run all tests
nvim --headless -u tests/init.lua -c "PlenaryBustedDirectory tests/plenary/ {minimal_init = './tests/init.lua'}" -c "qa"

# Run a single test file
nvim --headless -u tests/init.lua -c "PlenaryBustedFile tests/plenary/<spec_file>.lua {minimal_init = './tests/init.lua'}" -c "qa"
```

Tests use `plenary.nvim` (busted-compatible): `describe`/`it`/`assert` with `luassert.spy` for mocking.

### Doc Generation

```bash
bash scripts/doc-gen.sh
```

Uses `vimcats` to generate `doc/anki.txt` from LuaCATS annotations in `init.lua` and `config.lua`, then generates `doc/tags` via `:helptags` so `:help anki` works.

## Code Style

### Formatting

- 2-space indentation (no tabs), no trailing whitespace.
- Strings: mixed quotes; follow surrounding context.

### Imports

```lua
local config = require("anki.config")
local Note = require("anki.classes.note")
```
- Always `local <name> = require("<module>")`. Never alias to different names.
- Class imports use PascalCase matching the class name.

### Module Pattern

```lua
local M = {}

function M.some_function()
  -- ...
end

return M
```
All modules expose a table `M`. Functions defined as `function M.func_name(...)` or `M.func_name = function(...)`. Always `return M` at end.

### Class Pattern

```lua
local M = {}
M.__index = M
M.Note = M  -- EmmyLua type alias

function M:new(o)
  o = o or {}
  assert(o.deck_name, "Note requires a 'deck_name'")
  setmetatable(o, { __index = self, __tostring = function(tbl) ... end })
  return o
end
```
- `M.ClassName = M` for EmmyLua type aliasing.
- `assert()` for required constructor fields.
- `setmetatable(o, { __index = self })` for inheritance.

### Naming Conventions

- **Variables/functions:** `snake_case` (e.g., `async_safe_call`, `delete_note`, `deck_name`)
- **Classes/constructors:** `PascalCase` (e.g., `EditorContext`, `Field`, `Note`, `UI`)
- **Module-local helpers:** `snake_case` (e.g., `format_note_display`)
- **Constants/config:** `snake_case` (e.g., `M.defaults`, `M.options`)

### Error Handling

Three patterns, used in specific contexts:

1. **`error()` with module prefix** — Argument validation in general modules:
   ```lua
   error("[anki.nvim][editor] create_note: deck_name must be a string")
   ```

2. **`assert()`** — Required fields in class constructors:
   ```lua
   assert(o.deck_name, "Note requires a 'deck_name'")
   ```

3. **`async_safe_call()`** — All AnkiConnect API calls. Asynchronous wrapper that calls an ankiconnect function with callback-based error handling. Checks response for errors and reports via `notification.error()`. Callbacks are scheduled via `vim.schedule` to run on the main event loop.

Always prefix error messages with `[anki.nvim][<module>]` and include the function name.

### Notifications

```lua
notification.error("message")  -- Errors
notification.warn("message")   -- Warnings
notification.info("message")   -- Info
```

### Comments and Annotations

- `---` (three dashes) for EmmyLua/LuaCATS doc annotations (`---@param`, `---@return`, `---@class`, `---@field`).
- `--` (two dashes) for inline comments.
- Use `---@mod`, `---@brief`, `---@usage` in `init.lua` and `config.lua` for vimcats doc generation.
- Prefer `---@param` over `-- @param` for new code.

## Key Patterns

### AnkiConnect Communication

All calls go through `ankiconnect.lua`:
- **Asynchronous** HTTP POST via `plenary.curl` (with `callback` parameter) to `http://localhost:8765`
- Request format: `{ action = ..., version = 6, params = ... }`
- `params` defaults to `vim.empty_dict()` (not `{}`) to avoid null in JSON
- All calls are async and accept a callback as the last argument: `on_result(result, error)`
- All calls wrapped in `async_safe_call()` which handles errors and schedules callbacks via `vim.schedule`

### Configuration

- `config.defaults` — Default values; `config.options` — Merged config (accessed by all modules)
- Deep merge: `vim.tbl_deep_extend("force", M.defaults, opts or {})`

### State

- `state.lua` is a singleton holding `counter`, `current_note`, and `ui`
- UI state tracks window/buffer IDs, notes list, and current filter deck