# Agent Instructions for anki.nvim

Guidelines for AI agents working on this Neovim plugin codebase.

## Project Overview

anki.nvim is a Neovim plugin for creating and managing Anki flashcards from the editor. It communicates with Anki via the AnkiConnect addon over HTTP using `plenary.curl`.

**Dependencies:** `plenary.nvim` (required), `nvim-notify` (optional, falls back to `vim.notify`), AnkiConnect addon (external, requires Anki running locally).

**Directory layout:**
- `lua/anki/` — Plugin source
  - `init.lua` — Entry point (`setup()`, `open()`, user command)
  - `config.lua` — Default options and merge
  - `state.lua` — Singleton state (`counter`, `current_notes`, `current_template`, `ui`)
  - `api.lua` — High-level note operations (send, pull, delete)
  - `ankiconnect.lua` — Low-level AnkiConnect HTTP communication
  - `editor.lua` — Note editor buffer/tab management (per-tabpage)
  - `template_editor.lua` — Card template editor (per-tabpage tab with Front/Back/CSS splits)
  - `media.lua` — Media attachment helpers
  - `notification.lua` — Notification wrapper (nvim-notify or vim.notify)
  - `utils.lua` — Utilities (`split`, `async_safe_call`, `escape_search_query`, `get_visual_line_range`)
- `lua/anki/classes/` — Class modules (EditorContext, Field, Note, UI)
- `lua/anki/ui/` — UI operations (windows, operations, deck_ops, note_ops, profile_ops, model_ops, media_browser, help)
- `tests/plenary/` — Test specs (api, ankiconnect, classes, config, help, media, media_browser, model_ops, notification, template_editor, utils, windows)
- `doc/` — Vim help docs and tags file (generated via `scripts/doc-gen.sh`)

## Build, Lint, and Test

- **Build:** No build step. Pure Lua Neovim plugin.
- **Format:** `stylua` (2-space indent). Run manually: `stylua lua/`. The git pre-commit hook auto-formats staged `.lua` files. **Gotcha:** the hook requires `stylua` to be available in `PATH`.
- **Lint:** No linter configured.
- **Type check:** `.luarc.json` only declares `vim` as a global. No LuaLS type-checking CI.

### Test Commands

```bash
# Run all tests
nvim --headless -u tests/init.lua -c "PlenaryBustedDirectory tests/plenary/ {minimal_init = './tests/init.lua'}" -c "qa"

# Run a single test file
nvim --headless -u tests/init.lua -c "PlenaryBustedFile tests/plenary/<spec_file>.lua {minimal_init = './tests/init.lua'}" -c "qa"
```

Tests use `plenary.nvim` (busted-compatible): `describe`/`it`/`assert` with `luassert.spy` for mocking. `tests/init.lua` adds plenary to runtimepath.

### Doc Generation

```bash
bash scripts/doc-gen.sh
```

Uses `vimcats` to generate `doc/anki.txt` from LuaCATS annotations in `init.lua` and `config.lua`, then generates `doc/tags` via `:helptags`.

## Code Style

### Imports

```lua
local config = require("anki.config")
local Note = require("anki.classes.note")
```
- Always `local <name> = require("<module>")`. Never alias to different names.
- Class imports use PascalCase matching the class name.

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

3. **`async_safe_call()`** — All AnkiConnect API calls. Wraps the call with pcall and `vim.schedule` for callback scheduling. Callbacks receive `(result, error)` where exactly one is nil.

Always prefix error messages with `[anki.nvim][<module>]` and include the function name.

### Notifications

```lua
notification.error("message")  -- Errors
notification.warn("message")   -- Warnings
notification.info("message")   -- Info
```

### Comments and Annotations

- `---` (three dashes) for LuaCATS doc annotations (`---@param`, `---@return`, `---@class`, `---@field`).
- `--` (two dashes) for inline comments.
- Use `---@mod`, `---@brief`, `---@usage` in `init.lua` and `config.lua` for vimcats doc generation.
- Prefer `---@param` over `-- @param` for new code.

## Architecture Gotchas

### `vim.empty_dict()` not `{}`

AnkiConnect request `params` must default to `vim.empty_dict()` (not `{}`). Using `{}` serializes to `null` in JSON; `vim.empty_dict()` serializes to `{}`. All ankiconnect functions use this default.

### Tabpage handles vs tab numbers

`vim.api.nvim_get_current_tabpage()` returns a handle (opaque integer), not a 1-indexed tab number. When calling `:tabclose`, use `vim.api.nvim_tabpage_get_number(tabid)` to get the correct tab number. Passing a raw handle to `:tabclose` closes the wrong tab or errors.

### `E784: Cannot close last tab page`

Never call `:tabclose` unconditionally. If the tab being closed is the last tab, Neovim throws `E784`. Always guard:
```lua
if #vim.api.nvim_list_tabpages() > 1 then
    vim.cmd("tabclose " .. tab_number)
else
    vim.cmd("enew")  -- or just clean up buffers without closing
end
```

This applies to `operations.close()`, `editor.delete_note_buffers()`, `editor.kill_all()`, and `template_editor.close()`.

### Per-tabpage state for note and template editors

Both `state.current_notes` and `state.current_template` are tables keyed by tabpage ID (`table<integer, ...>`), not single values. Multiple editors can be open simultaneously. Always look up state by tabpage:

```lua
local tabid = vim.api.nvim_get_current_tabpage()
local note = anki_state.current_notes[tabid]
```

When closing, clean up only the matching entry: `anki_state.current_notes[tabid] = nil`.

To find which note owns a buffer, use `editor.find_note_by_bufnr(bufnr)` which searches all open notes. Do not access `current_notes` as a singleton.

### Buffer naming must be unique across tabs

Both note and template editor buffer names include the tabpage ID to avoid `E95: Buffer with this name already exists`:
```lua
-- Note editors:
vim.api.nvim_buf_set_name(buf, "anki://" .. tabid .. "/" .. field_name .. "_" .. counter)
-- Template editors:
vim.api.nvim_buf_set_name(buf, "anki-template://" .. tabid .. "/Front_" .. model_name)
```

### Note editors open in separate tabs

Each note editor opens in its own tab via `tabnew` (not in the deck/note browser tab). The deck/note browser is a single tab with a horizontal split (decks above, notes below). Pressing `q` on a note editor tab closes that tab. If the same note is already open, `editor.focus_note_by_id()` switches to its existing tab instead of opening a duplicate.

### `async_safe_call` callback scheduling

All callbacks in `async_safe_call` are wrapped in `vim.schedule()`. Code that modifies buffers or windows must account for async execution. The `on_result(result, error)` callback receives exactly one nil: on success `on_result(data, nil)`, on failure `on_result(nil, error)`.

## Key Patterns

### AnkiConnect Communication

All calls go through `ankiconnect.lua`:
- Asynchronous HTTP POST via `plenary.curl` (with `callback` parameter) to `http://localhost:8765`
- Request format: `{ action = ..., version = 6, params = ... }`
- All calls accept a callback as the last argument: `on_result(result, error)`
- All calls wrapped in `async_safe_call()`

### Configuration

- `config.defaults` — Default values; `config.options` — Merged config (accessed by all modules)
- Deep merge: `vim.tbl_deep_extend("force", M.defaults, opts or {})`

### State

- `state.lua` is a singleton holding `counter`, `current_notes` (per-tabpage table), `current_template` (per-tabpage table), and `ui`
- UI state tracks window/buffer IDs, notes list, and current filter deck
- The `UI` class no longer has an `editor_win_id` field; note editors live in separate tabs