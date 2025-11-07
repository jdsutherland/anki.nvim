---@class AnkiConfig
---@field url string
---@field timeout number
---@field prefix string
---@field default_mappings boolean
---@field gui_browse_enabled boolean
---@field create_user_commands boolean

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
