local anki_state = require("anki.state")
local utils = require("anki.utils")
local ankiconnect = require("anki.ankiconnect")
local editor = require("anki.editor")

local M = {}

--- Formats a note for display in the buffer.
-- @param note table The note object.
-- @return string The formatted note string.
local function format_note_display(note)
	local display = ""
	for key, field in pairs(note.fields) do
		display = display .. " [" .. key .. "]> " .. string.gsub(field.value, "[\r\n]", " ")
	end
	return display
end

--- Displays a list of notes in the note buffer, updating state.
-- @param notes_info table List of note info tables.
-- @param filter_name string|nil The filter (deck) name.
local function display_notes_in_buffer(notes_info, filter_name)
	if not notes_info then
		return
	end

	anki_state.ui.current_filter = filter_name
	anki_state.ui.notes = notes_info

	local note_lines = {}
	for _, note in ipairs(notes_info) do
		table.insert(note_lines, format_note_display(note))
	end
	vim.api.nvim_buf_set_lines(anki_state.ui.note_buf_id, 0, -1, false, note_lines)
end

--- Retrieves note information for a given query string.
-- @param query string The search query for notes.
-- @return table|nil List of note info tables, or nil on failure.
local function get_notes_for_query(query)
	local note_ids = utils.safe_call(ankiconnect.find_notes, query)
	if not note_ids then
		return nil
	end

	return utils.safe_call(ankiconnect.notes_info, note_ids)
end

--- Updates the deck buffer with the latest deck names from Anki.
local function update_decks_view()
	local deck_names = utils.safe_call(ankiconnect.deck_names)
	if not deck_names then
		return
	end
	anki_state.ui.decks = deck_names
	vim.api.nvim_buf_set_lines(anki_state.ui.deck_buf_id, 0, -1, false, deck_names)
end

--- Refreshes the note buffer based on the current deck filter.
local function update_notes_view()
	local deck_name = anki_state.ui.current_filter
	local query = ""
	if deck_name then
		query = string.format('"deck:%s"', deck_name)
	end
	local notes_info = get_notes_for_query(query)
	display_notes_in_buffer(notes_info, deck_name)
end

--- Refreshes both the deck and note buffers.
function M.refresh_all()
	update_decks_view()
	update_notes_view()
end

--- Refreshes the deck buffer.
function M.refresh_decks()
	update_decks_view()
end

--- Refreshes the note buffer.
function M.refresh_notes()
	update_notes_view()
end

--- Shows all notes, ignoring any deck filter.
function M.show_all_notes()
	local notes_info = get_notes_for_query("")
	display_notes_in_buffer(notes_info, nil)
end

--- Updates the note buffer based on the currently selected deck.
function M.select_deck()
	local line = vim.api.nvim_get_current_line()
	local deck_name = line
	if deck_name then
		local query = string.format('"deck:%s"', deck_name)
		local notes_info = get_notes_for_query(query)
		display_notes_in_buffer(notes_info, deck_name)
	end
end

--- Opens the Anki UI, creating windows and initializing state.
function M.open()
	local windows = require("anki.ui.windows")

	if windows.focus_existing_window() then
		return
	end

	if not windows.check_anki_permissions(ankiconnect) then
		return
	end

	local deck_win_id = windows.create_layout()
	windows.setup_deck_keymaps(anki_state.ui.deck_buf_id)
	windows.setup_note_keymaps(anki_state.ui.note_buf_id)

	-- Initialize UI data
	update_decks_view()
	M.show_all_notes()

	anki_state.ui.win_id = deck_win_id

	editor.setup_editor_quit_keybinding()
end

--- Closes the Anki UI window and cleans up buffers.
function M.close()
	if anki_state.ui.deck_buf_id and vim.api.nvim_buf_is_valid(anki_state.ui.deck_buf_id) then
		vim.api.nvim_buf_delete(anki_state.ui.deck_buf_id, { force = true })
	end
	if anki_state.ui.note_buf_id and vim.api.nvim_buf_is_valid(anki_state.ui.note_buf_id) then
		vim.api.nvim_buf_delete(anki_state.ui.note_buf_id, { force = true })
	end
	anki_state.ui.win_id = nil
	anki_state.ui.deck_buf_id = nil
	anki_state.ui.note_buf_id = nil
	anki_state.ui.editor_win_id = nil

	vim.cmd("tabclose")
end

return M
