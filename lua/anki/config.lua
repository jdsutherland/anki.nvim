---@class AnkiConfig
---@field url string
---@field timeout number
---@field prefix string
---@field default_mappings boolean
---@field gui_browse_enabled boolean
---@field create_user_commands boolean
---@field mappings table

---
--- anki.config
---
--- Handles plugin configuration, default options, and user overrides.
---
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

---@param opts AnkiConfig | nil
M.setup = function(opts)
	if opts ~= nil and type(opts) ~= "table" then
		error("[anki.nvim][config] setup: opts must be a table or nil")
	end
	M.options = vim.tbl_deep_extend("force", M.defaults, opts or {})
end

return M
