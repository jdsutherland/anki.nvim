# Agent Instructions for anki.nvim

Guidelines for AI agents working on this Neovim plugin codebase.

## Project Overview

anki.nvim is a Neovim plugin for creating and managing Anki flash cards directly from the editor. It communicates with the Anki desktop app via the AnkiConnect addon over HTTP.

**Dependencies:**
- `plenary.nvim` (required) — HTTP client via `plenary.curl`
- `nvim-notify` (optional) — Enhanced notifications; falls back to `vim.notify`
- AnkiConnect addon (external) — Must be installed in Anki

## Project Structure

```
lua/anki/
  init.lua              # Plugin entry point: setup(), keymaps, :Anki command
  config.lua            # Configuration defaults and deep-merge logic
  api.lua               # High-level note operations (send, pull, delete)
  ankiconnect.lua        # Low-level AnkiConnect HTTP API wrapper (plenary.curl)
  editor.lua            # Note editor buffer/window management
  notification.lua       # Notification wrapper (nvim-notify or vim.notify)
  state.lua             # Global singleton plugin state
  utils.lua             # Utilities: safe_call, split
  classes/
    editor_context.lua  # EditorContext class (bufnr, winid, tabid)
    field.lua           # Field class (name, editor_context)
    note.lua            # Note class (fields, tags, deck_name, model_name, id)
    ui.lua              # UI class (window/buffer IDs, notes, decks)
  ui/
    windows.lua          # Window layout creation and keymap setup
    operations.lua       # Core UI operations (open, close, refresh, select)
    deck_ops.lua         # Deck operations (create, delete, rename, gui)
    note_ops.lua         # Note operations (add, edit, delete, move, gui)
    profile_ops.lua      # Profile switching
    help.lua             # Help popup window
tests/
  init.lua               # Test bootstrap (adds plenary to runtime path)
  plenary/
    classes_spec.lua      # Tests for EditorContext, Field, Note, UI
    config_spec.lua       # Tests for config module
    notification_spec.lua # Tests for notification module
    utils_spec.lua        # Tests for utils module
doc/
  anki.txt               # Vim help docs (generated via vimcats)
scripts/
  doc-gen.sh             # Generates doc/anki.txt from LuaCATS annotations
pre-commit.sh            # Self-installing pre-commit hook (runs stylua)
```

## Build, Lint, and Test

- **Build:** No build step required. This is a pure Lua Neovim plugin.
- **Format:** Uses `stylua` auto-formatting via the `pre-commit.sh` hook.
- **Lint:** No separate linting tool configured.

### Test Commands

```bash
# Run all tests
nvim --headless -u tests/init.lua -c "PlenaryBustedDirectory tests/plenary/ {minimal_init = './tests/init.lua'}" -c "qa"

# Run a single test file
nvim --headless -u tests/init.lua -c "PlenaryBustedFile tests/plenary/classes_spec.lua {minimal_init = './tests/init.lua'}" -c "qa"
nvim --headless -u tests/init.lua -c "PlenaryBustedFile tests/plenary/config_spec.lua {minimal_init = './tests/init.lua'}" -c "qa"
nvim --headless -u tests/init.lua -c "PlenaryBustedFile tests/plenary/notification_spec.lua {minimal_init = './tests/init.lua'}" -c "qa"
nvim --headless -u tests/init.lua -c "PlenaryBustedFile tests/plenary/utils_spec.lua {minimal_init = './tests/init.lua'}" -c "qa"
```

Tests use `plenary.nvim` (busted-compatible) with `describe`/`it`/`assert` and `luassert.spy` for mocking.

### Doc Generation

```bash
bash scripts/doc-gen.sh
```

Uses `vimcats` to generate `doc/anki.txt` from LuaCATS/EmmyLua annotations in `init.lua` and `config.lua`.

## Code Style

### Formatting

- **Indentation:** 2 spaces (no tabs).
- **Strings:** Mixed single and double quotes throughout the codebase; follow surrounding context.
- **No trailing whitespace.**

### Imports

```lua
local config = require("anki.config")
local Note = require("anki.classes.note")
```

- Always use `local <name> = require("<module>")`.
- Class imports use PascalCase matching the class name.
- Never alias imports to different names.

### Module Pattern

```lua
local M = {}

function M.some_function()
  -- ...
end

return M
```

- All modules expose functionality via a table named `M`.
- Define functions as `function M.func_name(...)` or `M.func_name = function(...)`.
- Always `return M` at the end.

### Class Pattern

Classes use Lua metatables following this pattern:

```lua
local M = {}
M.__index = M
M.Note = M

function M:new(o)
  o = o or {}
  assert(o.deck_name, "Note requires a 'deck_name'")
  setmetatable(o, { __index = self, __tostring = ... })
  return o
end
```

- Use `M.ClassName = M` for EmmyLua type aliasing.
- Use `assert()` for required fields in constructors.
- Use `setmetatable(o, { __index = self })` for inheritance.

### Naming Conventions

- **Variables and functions:** `snake_case` (e.g., `safe_call`, `delete_note`, `deck_name`)
- **Classes/constructors:** `PascalCase` (e.g., `EditorContext`, `Field`, `Note`, `UI`)
- **Module-local helpers:** `snake_case` (e.g., `format_note_display`)
- **Constants/config:** `snake_case` (e.g., `M.defaults`, `M.options`)

### Error Handling

There are three error handling patterns, used in different contexts:

1. **`error()` with module prefix** — For argument validation in general modules:
   ```lua
   error("[anki.nvim][editor] create_note: deck_name must be a string")
   ```

2. **`assert()`** — For required fields in class constructors:
   ```lua
   assert(o.deck_name, "Note requires a 'deck_name'")
   ```

3. **`safe_call()`** — For all AnkiConnect API calls. Wraps `pcall` and checks the AnkiConnect response for errors. Returns `result` on success or `nil` on failure, and sends `notification.error()` on failure.

Always prefix error messages with `[anki.nvim][<module>]` and include the function name when applicable.

### Notifications

Use the notification module for user-facing messages:
```lua
notification.error("message")  -- Errors
notification.warn("message")    -- Warnings
notification.info("message")    -- Info
```

### Comments and Annotations

- **`---`** (three dashes) for EmmyLua/LuaCATS documentation annotations:
  ```lua
  ---Sends a note to Anki
  ---@param note Note The note to send
  ---@return boolean
  ```

- **`--`** (two dashes) for inline comments and brief notes.

- Use `---@mod`, `---@brief`, and `---@usage` in `init.lua` and `config.lua` for vimcats doc generation.

- Other modules use a mix of `---@param` (EmmyLua) and `-- @param` (LuaDoc) styles. Prefer `---@param` for new code.

### Type Checking

- No static type checking tool is configured.
- Use `type()` for runtime type checks when needed.
- Use EmmyLua `---@class`, `---@field`, `---@param`, `---@return` annotations for documentation and LSP support.

## Key Patterns

### AnkiConnect Communication

All AnkiConnect calls go through `ankiconnect.lua`:
- Synchronous HTTP POST via `plenary.curl` to `http://localhost:8765`
- Request format: `{ action = ..., version = 6, params = ... }`
- `params` defaults to `vim.empty_dict()` (not `{}`) to avoid null in JSON
- All calls wrapped in `safe_call()` for error handling

### Configuration

- `config.defaults` — Default configuration values
- `config.options` — Merged configuration (accessed by all other modules)
- Deep merge via `vim.tbl_deep_extend("force", M.defaults, opts or {})`

### State

- `state.lua` is a singleton holding `counter`, `current_note`, and `ui`
- UI state tracks window/buffer IDs, notes list, and current filter

## External Documentation

- AnkiConnect API: https://git.sr.ht/~foosoft/anki-connect