---@mod anki.config Configuration
---@brief [[
--- Configuration module for anki.nvim.
---
--- This module holds the default options and merges user-provided overrides
--- via `setup()`. See |AnkiConfig| for the full list of options.
---@brief ]]

---@class AnkiConfig
---@field url string AnkiConnect server URL.
---@field timeout number HTTP request timeout in milliseconds.
---@field prefix string Keymap prefix to open the Anki UI (default: `"<leader>a"`).
---@field default_mappings boolean Whether to auto-set the prefix keymap.
---@field gui_browse_enabled boolean Whether to open Anki GUI when sending/pulling notes.
---@field create_user_commands boolean Whether to create the `:Anki` user command.
---@field mappings AnkiMappings Buffer-local keymappings for deck, note, and editor panes.

---@class AnkiMappings
---@field deck AnkiDeckMappings Deck pane keymaps.
---@field note AnkiNoteMappings Note pane keymaps.
---@field editor AnkiEditorMappings Editor pane keymaps.

---@class AnkiDeckMappings
---@field show_help string Show Help (default: `"?"`)
---@field close string Close (default: `"q"`)
---@field select_deck string Select deck (default: `"<CR>"`)
---@field delete_deck string Delete deck (default: `"d"`)
---@field create_deck string Create deck (default: `"c"`)
---@field add_note string Add note (default: `"a"`)
---@field rename_deck string Rename deck (default: `"m"`)
---@field gui_deck string Open in Anki GUI (default: `"o"`)
---@field refresh_decks string Refresh decks (default: `"r"`)
---@field switch_profile string Switch profile (default: `"p"`)

---@class AnkiNoteMappings
---@field show_help string Show Help (default: `"?"`)
---@field close string Close (default: `"q"`)
---@field edit_note string Edit note (default: `"<CR>"`)
---@field delete_note string Delete note (default: `"d"`)
---@field gui_note string Open in Anki GUI (default: `"o"`)
---@field show_all_notes string Show all notes (default: `"a"`)
---@field refresh_notes string Refresh notes (default: `"r"`)
---@field move_note_to_deck string Move note to another deck (default: `"m"`)

---@class AnkiEditorMappings
---@field send_note string Send note to Anki (default: `"<leader>w"`)
---@field pull_note string Pull note from Anki (default: `"<leader>p"`)
---@field delete_note string Delete note (default: `"<leader>r"`)
---@field kill_note string Close note buffer (default: `"<leader>k"`)
---@field show_help string Show Help (default: `"?"`)

local M = {}

---@type AnkiConfig
M.defaults = {
	url = "http://localhost:8765",
	timeout = 500,
	prefix = "<leader>a",
	default_mappings = true,
	gui_browse_enabled = true,
	create_user_commands = true,
	mappings = {
		deck = {
			show_help = "?",
			close = "q",
			select_deck = "<CR>",
			delete_deck = "d",
			create_deck = "c",
			add_note = "a",
			rename_deck = "m",
			gui_deck = "o",
			refresh_decks = "r",
			switch_profile = "p",
		},
		note = {
			show_help = "?",
			close = "q",
			edit_note = "<CR>",
			delete_note = "d",
			gui_note = "o",
			show_all_notes = "a",
			refresh_notes = "r",
			move_note_to_deck = "m",
		},
		editor = {
			send_note = "<leader>w",
			pull_note = "<leader>p",
			delete_note = "<leader>r",
			kill_note = "<leader>k",
			show_help = "?",
		},
	},
}

---@type AnkiConfig
M.options = vim.tbl_deep_extend("force", {}, M.defaults)

--- Merge user options with defaults (deep-extend).
---@param opts AnkiConfig|nil Partial or full configuration table to override defaults.
---@see AnkiConfig
M.setup = function(opts)
	if opts ~= nil and type(opts) ~= "table" then
		error("[anki.nvim][config] setup: opts must be a table or nil")
	end
	M.options = vim.tbl_deep_extend("force", M.defaults, opts or {})
end

return M
