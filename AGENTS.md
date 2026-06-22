# Agent Instructions for anki.nvim

Neovim plugin for creating/managing Anki flashcards via AnkiConnect over HTTP (`plenary.curl`).

**Dependencies:** `plenary.nvim` (required), `nvim-notify` (optional, falls back to `vim.notify`), `snacks.nvim` (optional, for media browser image preview), AnkiConnect addon (external, requires Anki running locally).

## Commands

```bash
# Format (2-space indent, stylua) — also runs via pre-commit hook
stylua lua/ tests/

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
  ankiconnect.lua    — low-level HTTP to AnkiConnect (notes + cards wrappers)
  editor.lua         — note editor buffer/tab management (per-tabpage)
  template_editor.lua — card template editor (per-tabpage, Front/Back/CSS splits)
  media.lua          — media attachment helpers
  notification.lua   — wraps nvim-notify or vim.notify
  utils.lua          — split, async_safe_call, escape_search_query, get_visual_line_range
  classes/           — EditorContext, Field, Note, UI
  ui/                — windows, operations (HEADER_LINES + view_mode), deck_ops, note_ops, profile_ops, model_ops, media_browser, help
tests/plenary/       — plenary test specs
doc/                 — generated help docs (do not edit directly)
```

## Architecture Gotchas

### `vim.empty_dict()` not `{}`

AnkiConnect request `params` must default to `vim.empty_dict()` (not `{}`). `{}` serializes to `null` in JSON; `vim.empty_dict()` serializes to `{}`.

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

### Browser buffers have a 3-line header

The deck and notes buffers prepend a hint line, a `== Mode | filter ==` header, and a blank line before content. `operations.HEADER_LINES = 3` is the offset.

Note/deck lookups by cursor line MUST subtract `HEADER_LINES`:
- `note_ops`: `entry_at_cursor()` / `entries_in_range()` helpers (already do this)
- `deck_ops`: `deck_at_cursor()` / `decks_in_range()` helpers
- `operations.select_deck`: reads `anki_state.ui.decks[idx]` with `idx = line - HEADER_LINES`

New content-rendering functions must use `render_with_header(bufnr, context, lines)` (defined in `operations.lua`), not raw `nvim_buf_set_lines`.

### Notes vs cards view mode

`anki_state.ui.view_mode` is `"notes"` (default) or `"cards"`. `operations.toggle_view_mode()` flips it and re-runs `update_notes_view`, which branches:
- notes → `find_notes` + `notes_info` (existing path)
- cards → `find_cards` + `cards_info` (card wrappers in `ankiconnect.lua`)

`note_ops` (`edit_note`, `delete_note`, `move_note_to_deck`, `gui_note`) branch on `view_mode`: in cards mode, `edit_note` resolves the parent note via `noteId`, `gui_note` uses `cid:<cardId>` (vs `nid:<noteId>`), `move_note_to_deck` operates on card ids directly. `anki_state.ui.notes` and `anki_state.ui.cards` are parallel indexed lists — read the one matching `view_mode`.

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
- `state.ui` (`UI` class) holds: `win_id` (deck window), `deck_buf_id`, `note_buf_id`, `notes` (notesInfo rows), `cards` (cardsInfo rows), `decks`, `current_filter` (query string, e.g. `"deck:Foo"`), `view_mode` (`"notes"` or `"cards"`)
- Only the deck window id is stored in `win_id`; the note window is looked up via `vim.fn.bufwinid(anki_state.ui.note_buf_id)` when needed
- Note editors live in separate tabs, not in the browser tab
