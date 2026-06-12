local config = require("anki.config")

local M = {}

--- Closes the help window if it is open.
function M.close_help()
	-- Iterate through all buffers to find the help buffer
	for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
		if vim.api.nvim_buf_is_valid(bufnr) then
			local bufname = vim.api.nvim_buf_get_name(bufnr)
			if bufname:find("Anki Help") then
				-- Delete the buffer directly; window closes automatically
				vim.api.nvim_buf_delete(bufnr, { force = true })
				return
			end
		end
	end
end

--- Shows the help window for the given context (decks, notes, or editor).
-- @param context string|nil The context to show help for. Defaults to 'decks'.
function M.show_help(context)
	context = context or "decks"

	-- Check if cursor is already on the help window
	local current_bufnr = vim.api.nvim_win_get_buf(0)
	local current_bufname = vim.api.nvim_buf_get_name(current_bufnr)
	if current_bufname:find("Anki Help") then
		M.close_help()
		return
	end

	-- Close existing help window if open
	M.close_help()

	local help_lines = {}

	if context == "decks" then
		local m = config.options.mappings.deck
		help_lines = {
			"Anki.nvim Help - Decks",
			"",
			m.show_help .. " - Show this help window",
			m.close .. " - Close the Anki UI tab",
			m.select_deck .. " - Select a deck and show its notes",
			m.delete_deck .. " - Delete Deck",
			m.create_deck .. " - Create Deck",
			m.add_note .. " - Add Note",
			m.rename_deck .. " - Rename Deck",
			m.gui_deck .. " - Open in the Anki GUI",
			m.refresh_decks .. " - Refresh Decks",
			m.switch_profile .. " - Switch Profile",
			m.edit_templates .. " - Edit card templates",
			m.create_model .. " - Create new model/note type",
		}
	elseif context == "notes" then
		local m = config.options.mappings.note
		help_lines = {
			"Anki.nvim Help - Notes",
			"",
			m.show_help .. " - Show this help window",
			m.close .. " - Close the Anki UI tab",
			m.edit_note .. " - Edit note",
			m.show_all_notes .. " - Show all notes",
			m.delete_note .. " - Delete note",
			m.gui_note .. " - Open in the Anki GUI",
			m.refresh_notes .. " - Refresh Notes",
		}
	elseif context == "editor" then
		local m = config.options.mappings.editor
		help_lines = {
			"Anki.nvim Help - Editor",
			"",
			m.show_help .. " - Show this help window",
			m.close .. " - Close the note editor",
			m.send_note .. " - Write/Send note to Anki",
			m.pull_note .. " - Pull note from Anki",
			m.delete_note .. " - Remove/Delete note from Anki",
			m.attach_media .. " - Attach media (image/audio/video) [field buffers only]",
		}
	elseif context == "media_browser" then
		help_lines = {
			"Anki.nvim Help - Media Browser",
			"",
			"g? - Show this help window",
			"<Enter> - Insert selected media reference",
			"q / <Esc> - Close the media browser",
			"j/k - Navigate the file list",
		}
	elseif context == "templates" then
		local m = config.options.mappings.template
		help_lines = {
			"Anki.nvim Help - Templates",
			"",
			m.show_help .. " - Show this help window",
			m.save_template .. " - Save template changes to Anki",
			m.pull_template .. " - Pull latest template from Anki",
			m.switch_card .. " - Switch card (for multi-card models)",
			m.close_template .. " - Close the template editor",
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
