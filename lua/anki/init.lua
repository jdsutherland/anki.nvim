local config = require("anki.config")
local operations = require("anki.ui.operations")

---
--- anki.init
---
--- Entry point for plugin setup. Handles user configuration, keymaps, and user commands.
---
local M = {}

--- Sets up the default keymaps if enabled in the config.
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

--- Sets up user commands if enabled in the config.
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
-- @param opts table|nil User configuration options.
function M.setup(opts)
	if opts ~= nil and type(opts) ~= "table" then
		error("[anki.nvim][init] setup: opts must be a table or nil")
	end
	config.setup(opts)
	setup_mappings()
	setup_commands()
end

return M
