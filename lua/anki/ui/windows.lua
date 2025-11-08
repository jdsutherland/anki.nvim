local anki_state = require("anki.state")
local notification = require("anki.notification")
local utils = require("anki.utils")
local config = require("anki.config")

local M = {}

--- Sets a normal mode keymap for a buffer with noremap and silent options.
-- @param bufnr number Buffer number
-- @param lhs string Left-hand side (key)
-- @param rhs string Right-hand side (command)
local function set_buf_keymap(bufnr, mode, lhs, rhs)
	vim.api.nvim_buf_set_keymap(bufnr, mode, lhs, rhs, { noremap = true, silent = true })
end

--- Focuses the existing Anki window if it is valid.
-- @return boolean True if the window was focused, false otherwise.
function M.focus_existing_window()
	if anki_state.ui.win_id and vim.api.nvim_win_is_valid(anki_state.ui.win_id) then
		local tab_id = vim.api.nvim_win_get_tabpage(anki_state.ui.win_id)
		vim.api.nvim_set_current_tabpage(tab_id)
		vim.api.nvim_set_current_win(anki_state.ui.win_id)
		return true
	end
	return false
end

--- Checks and requests AnkiConnect permissions, displaying errors if denied.
-- @param ankiconnect table The AnkiConnect module or API object.
-- @return boolean True if permission is granted, false otherwise.
function M.check_anki_permissions(ankiconnect)
	local permission_response = utils.safe_call(ankiconnect.request_permission)
	if not permission_response then
		return false
	end

	if permission_response.permission == "denied" then
		notification.error([[[anki.nvim][windows] AnkiConnect permission denied. Please:
		1. Check the Anki popup dialog and grant permission
		2. Or add your origin to trusted origins in AnkiConnect config
    ]])
		return false
	elseif permission_response.permission ~= "granted" then
		notification.error("[anki.nvim][windows] Unexpected permission response from AnkiConnect")
		return false
	end

	return true
end

--- Creates the Anki UI layout with deck and note buffers in new windows.
-- @return number The window ID of the deck window.
function M.create_layout()
	vim.cmd("tabnew")
	anki_state.ui.editor_win_id = vim.api.nvim_get_current_win()

	anki_state.ui.deck_buf_id = vim.api.nvim_create_buf(false, true)
	anki_state.ui.note_buf_id = vim.api.nvim_create_buf(false, true)

	vim.api.nvim_buf_set_name(anki_state.ui.deck_buf_id, "Anki Decks")
	vim.api.nvim_buf_set_name(anki_state.ui.note_buf_id, "Anki Notes")

	vim.cmd("vnew")
	local deck_win_id = vim.api.nvim_get_current_win()
	vim.api.nvim_win_set_buf(deck_win_id, anki_state.ui.deck_buf_id)

	vim.cmd("new")
	local note_win_id = vim.api.nvim_get_current_win()
	vim.api.nvim_win_set_buf(note_win_id, anki_state.ui.note_buf_id)

	vim.api.nvim_set_current_win(deck_win_id)
	return deck_win_id
end

--- Sets up keymaps for the deck buffer.
-- @param bufnr number Buffer number for the deck list.
function M.setup_deck_keymaps(bufnr)
	local mappings = {
		show_help = "<Cmd>lua require('anki.ui.help').show_help('decks')<CR>",
		close = "<Cmd>lua require('anki.ui.operations').close()<CR>",
		select_deck = "<Cmd>lua require('anki.ui.operations').select_deck()<CR>",
		delete_deck = "<Cmd>lua require('anki.ui.deck_ops').delete_deck()<CR>",
		create_deck = "<Cmd>lua require('anki.ui.deck_ops').create_deck()<CR>",
		add_note = "<Cmd>lua require('anki.ui.note_ops').add_note()<CR>",
		rename_deck = "<Cmd>lua require('anki.ui.deck_ops').rename_deck()<CR>",
		gui_deck = "<Cmd>lua require('anki.ui.deck_ops').gui_deck()<CR>",
		refresh_decks = "<Cmd>lua require('anki.ui.operations').refresh_decks()<CR>",
	}

	for action, key in pairs(config.options.mappings.deck) do
		if mappings[action] then
			set_buf_keymap(bufnr, "n", key, mappings[action])
			if action == "delete_deck" then
				set_buf_keymap(bufnr, "v", key, mappings[action])
			end
		end
	end
end

--- Sets up keymaps for the note buffer, including visual mode mappings.
-- @param bufnr number Buffer number for the note list.
function M.setup_note_keymaps(bufnr)
	local mappings = {
		show_help = "<Cmd>lua require('anki.ui.help').show_help('notes')<CR>",
		close = "<Cmd>lua require('anki.ui.operations').close()<CR>",
		edit_note = "<Cmd>lua require('anki.ui.note_ops').edit_note()<CR>",
		delete_note = "<Cmd>lua require('anki.ui.note_ops').delete_note()<CR>",
		gui_note = "<Cmd>lua require('anki.ui.note_ops').gui_note()<CR>",
		show_all_notes = "<Cmd>lua require('anki.ui.operations').show_all_notes()<CR>",
		refresh_notes = "<Cmd>lua require('anki.ui.operations').refresh_notes()<CR>",
		move_note_to_deck = "<Cmd>lua require('anki.ui.note_ops').move_note_to_deck()<CR>",
	}

	for action, key in pairs(config.options.mappings.note) do
		if mappings[action] then
			set_buf_keymap(bufnr, "n", key, mappings[action])
			if action == "delete_note" or action == "move_note_to_deck" then
				set_buf_keymap(bufnr, "v", key, mappings[action])
			end
		end
	end
end

return M
