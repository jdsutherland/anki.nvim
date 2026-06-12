# Agent Instructions for anki.nvim

Neovim plugin for creating/managing Anki flashcards via AnkiConnect over HTTP (`plenary.curl`).

**Dependencies:** `plenary.nvim` (required), `nvim-notify` (optional, falls back to `vim.notify`), `snacks.nvim` (optional, for media browser image preview), AnkiConnect addon (external, requires Anki running locally).

## Commands

```bash
# Format (2-space indent, stylua) — also runs via pre-commit hook
stylua lua/

# Run all tests
nvim --headless -u tests/init.lua -c "PlenaryBustedDirectory tests/plenary/ {minimal_init = './tests/init.lua'}" -c "qa"

# Run single test file
nvim --headless -u tests/init.lua -c "PlenaryBustedFile tests/plenary/<spec>.lua {minimal_init = './tests/init.lua'}" -c "qa"

# Regenerate docs (requires vimcats in PATH)
bash scripts/doc-gen.sh
```

No build step, no linter, no type-checking CI. `.luarc.json` only declares `vim` as a global.

**Pre-commit hook** auto-formats staged `.lua` files with `stylua`. Requires `stylua` in `PATH`.

Tests use `plenary.nvim` (busted-compatible): `describe`/`it`/`assert` with `luassert.spy`. `tests/init.lua` adds plenary to runtimepath.

## Architecture

```
lua/anki/
  init.lua           — setup(), open(), user command
  config.lua         — defaults + deep-merge
  state.lua          — singleton: counter, current_notes[tabid], current_template[tabid], ui
  api.lua            — high-level note ops (send, pull, delete)
  ankiconnect.lua    — low-level HTTP to AnkiConnect
  editor.lua         — note editor buffer/tab management (per-tabpage)
  template_editor.lua — card template editor (per-tabpage, Front/Back/CSS splits)
  media.lua          — media attachment helpers
  notification.lua   — wraps nvim-notify or vim.notify
  utils.lua          — split, async_safe_call, escape_search_query, get_visual_line_range
  classes/           — EditorContext, Field, Note, UI
  ui/                — windows, operations, deck_ops, note_ops, profile_ops, model_ops, media_browser, help
tests/plenary/       — plenary test specs
doc/                 — generated help docs (do not edit directly)
```

## Architecture Gotchas

### `vim.empty_dict()` not `{}`

AnkiConnect request `params` must default to `vim.empty_dict()` (not `{}`). `{}` serializes to `null` in JSON; `vim.empty_dict()` serializes to `{}`.

### Tabpage handles are not tab numbers

`vim.api.nvim_get_current_tabpage()` returns an opaque handle, not a 1-indexed tab number. To close a tab, convert with `vim.api.nvim_tabpage_get_number(tabid)`. Passing a raw handle to `:tabclose` closes the wrong tab or errors.

### `E784: Cannot close last tab page`

Never call `:tabclose` unconditionally. Guard:
```lua
if #vim.api.nvim_list_tabpages() > 1 then
    vim.cmd("tabclose " .. tab_number)
else
    vim.cmd("enew")
end
```
Applies to `operations.close()`, `editor.delete_note_buffers()`, `editor.kill_all()`, `template_editor.close()`.

### Per-tabpage state

`state.current_notes` and `state.current_template` are tables keyed by tabpage ID — not single values. Always look up by tabpage:
```lua
local tabid = vim.api.nvim_get_current_tabpage()
local note = anki_state.current_notes[tabid]
```
On close, nil out only the matching entry. To find which note owns a buffer, use `editor.find_note_by_bufnr(bufnr)` — do not treat `current_notes` as a singleton.

### Buffer names must be unique across tabs

Buffer names include the tabpage ID to avoid `E95`:
- Note editors: `"anki://" .. tabid .. "/" .. field_name .. "_" .. counter`
- Template editors: `"anki-template://" .. tabid .. "/Front_" .. model_name`

### Note editors open in separate tabs

Each note editor opens via `tabnew`, not inside the browser tab. The browser is a single tab with a horizontal split (decks above, notes below). If the same note is already open, `editor.focus_note_by_id()` switches to its existing tab.

### `async_safe_call` callback scheduling

All callbacks are wrapped in `vim.schedule()`. Buffer/window modifications must account for async execution. `on_result(result, error)` — exactly one is nil: success → `(data, nil)`, failure → `(nil, error)`.

## Code Conventions

### Imports

```lua
local config = require("anki.config")
local Note = require("anki.classes.note")
```
Always `local <name> = require("<module>")`. Never alias. Class imports use PascalCase matching the class name.

### Error messages

Prefix with `[anki.nvim][<module>]` and include the function name. Three patterns:

1. `error()` — argument validation in general modules
2. `assert()` — required fields in class constructors
3. `async_safe_call()` — wraps all AnkiConnect calls with pcall + vim.schedule

### Notifications

```lua
notification.error("message")
notification.warn("message")
notification.info("message")
```

### LuaCATS annotations

- `---` for doc annotations (`---@param`, `---@return`, `---@class`, `---@field`)
- `--` for inline comments
- `---@mod`, `---@brief`, `---@usage` in `init.lua` and `config.lua` only (for vimcats doc generation)
- Prefer `---@param` over `-- @param`

### AnkiConnect communication

All calls go through `ankiconnect.lua`: async HTTP POST via `plenary.curl` to `http://localhost:8765`. Request format: `{ action, version = 6, params }`. All calls accept callback as last arg: `on_result(result, error)`. All wrapped in `async_safe_call()`.

### Config

- `config.defaults` — default values; `config.options` — merged config (read by all modules)
- Deep merge: `vim.tbl_deep_extend("force", M.defaults, opts or {})`

### State

- `state.lua` is a singleton: `counter`, `current_notes` (per-tabpage), `current_template` (per-tabpage), `ui`
- The `UI` class has no `editor_win_id` field; note editors live in separate tabs