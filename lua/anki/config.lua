local M = {}

M.defaults = {
	url = "http://localhost:8765",
	timeout = 500,
	prefix = "<leader>a",
	default_mappings = true,
	quickdeck = "Refile",
	gui_browse_enabled = true,
	create_user_commands = true,
	custom_display = nil,
	custom_delete = nil,
	after_edit_buffer_hook = nil,
}

M.options = {}

M.setup = function(opts)
	M.options = vim.tbl_deep_extend("force", {}, M.defaults, opts or {})
end

return M
