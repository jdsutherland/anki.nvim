---@mod anki anki.nvim
---@brief [[
--- anki.nvim — Create, review, and manage Anki flashcards directly from Neovim.
---
--- Features:
---   • Browse decks and notes in a 3-pane split layout
---   • Create, edit, send, and delete notes without leaving Neovim
---   • Pull existing notes from Anki for editing
---   • Attach media (images, audio, video) to notes from local files, URLs, clipboard, or Anki collection
---   • Deck management (create, rename, delete, switch profile)
---   • Edit card templates (Front/Back HTML and CSS styling) for existing note types
---   • Create new note types (models) with custom fields and card templates
---   • Integrates with AnkiConnect (requires Anki running locally)
---
--- Quick start: >
---   require("anki").setup()
--- <
--- This opens a normal-mode mapping (default `<leader>a`) and/or the
--- `:Anki` user command to launch the UI.
---@brief ]]

local config = require("anki.config")
local operations = require("anki.ui.operations")

local M = {}

local function setup_mappings()
	if not config.options.default_mappings then
		return
	end
	vim.keymap.set(
		"n",
		config.options.prefix,
		operations.open,
		{ noremap = true, silent = true, desc = "[Anki] Open the main Anki window" }
	)
end

local function setup_commands()
	if not config.options.create_user_commands then
		return
	end

	vim.api.nvim_create_user_command("Anki", function()
		operations.open()
	end, {
		desc = "[Anki] Open the main Anki window",
		nargs = 0,
	})
end

--- Sets up the plugin with user configuration, keymaps, and commands.
--- When `default_mappings` is true (the default), a normal-mode mapping for
--- `prefix` (default `<leader>a`) is created to open the Anki UI.
--- When `create_user_commands` is true (the default), the `:Anki` user
--- command is created.
---@param opts AnkiConfig|nil Optional configuration table (see |anki-config|).
---@usage `require("anki").setup({ url = "http://localhost:8765" })`
function M.setup(opts)
	if opts ~= nil and type(opts) ~= "table" then
		error("[anki.nvim][init] setup: opts must be a table or nil")
	end
	config.setup(opts)
	setup_mappings()
	setup_commands()
end

return M
