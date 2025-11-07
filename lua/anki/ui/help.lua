local M = {}

--- Shows the help window for the given context (decks, notes, or editor).
-- @param context string|nil The context to show help for. Defaults to 'decks'.
function M.show_help(context)
	context = context or "decks"
	local help_lines = {}

	if context == "decks" then
		help_lines = {
			"Anki.nvim Help - Decks",
			"",
			"? - Show this help window",
			"q - Close the Anki UI tab",
			"<CR> - Select a deck and show its notes",
			"d - Delete Deck",
			"c - Create Deck",
			"a - Add Note",
			"m - Rename Deck",
			"o - Open in the Anki GUI",
			"r - Refresh Decks",
		}
	elseif context == "notes" then
		help_lines = {
			"Anki.nvim Help - Notes",
			"",
			"? - Show this help window",
			"q - Close the Anki UI tab",
			"<CR> - Edit note",
			"a - Show all notes",
			"d - Delete note",
			"o - Open in the Anki GUI",
			"r - Refresh Notes",
		}
	elseif context == "editor" then
		help_lines = {
			"Anki.nvim Help - Editor",
			"",
			"? - Show this help window",
			"q - Close the Anki UI tab (when no note is open)",
			"<leader>w - Write/Send note to Anki",
			"<leader>p - Pull note from Anki",
			"<leader>r - Remove/Delete note from Anki",
			"<leader>k - Kill/Close the note editor",
		}
	end

	local help_bufnr = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_name(help_bufnr, "Anki Help")
	vim.api.nvim_buf_set_lines(help_bufnr, 0, -1, false, help_lines)
	local width = 60
	local height = #help_lines + 2
	vim.api.nvim_open_win(help_bufnr, true, {
		relative = "editor",
		width = width,
		height = height,
		col = (vim.o.columns - width) / 2,
		row = (vim.o.lines - height) / 2,
		anchor = "NW",
		style = "minimal",
		border = "single",
		title = "Anki Help",
	})
	vim.api.nvim_buf_set_keymap(help_bufnr, "n", "q", "<Cmd>bd!<CR>", { noremap = true, silent = true })
end

return M
