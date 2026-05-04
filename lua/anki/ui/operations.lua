local anki_state = require("anki.state")
local config = require("anki.config")
local utils = require("anki.utils")
local ankiconnect = require("anki.ankiconnect")
local editor = require("anki.editor")

local M = {}

--- Formats a note for display in the buffer.
-- @param note table The note object.
-- @return string The formatted note string.
local function format_note_display(note)
	return config.options.note_formatter(note)
end

--- Displays a list of notes in the note buffer, updating state.
-- @param notes_info table List of note info tables.
-- @param filter_name string|nil The filter (deck) name.
local function display_notes_in_buffer(notes_info, filter_name)
	anki_state.ui.current_filter = filter_name
	anki_state.ui.notes = notes_info or {}

	local note_lines = {}
	for _, note in ipairs(notes_info or {}) do
		table.insert(note_lines, format_note_display(note))
	end
	vim.api.nvim_buf_set_lines(anki_state.ui.note_buf_id, 0, -1, false, note_lines)
end

--- Retrieves note information for a given query string asynchronously.
-- @param query string The search query for notes.
-- @param on_result function Callback: on_result(notes_info)
local function get_notes_for_query(query, on_result)
	utils.async_safe_call(ankiconnect.find_notes, { query }, function(note_ids, error)
		if error or not note_ids then
			on_result(nil)
			return
		end
		utils.async_safe_call(ankiconnect.notes_info, { note_ids }, function(notes_info, err2)
			if err2 then
				on_result(nil)
				return
			end
			on_result(notes_info)
		end)
	end)
end

--- Updates the deck buffer with the latest deck names from Anki asynchronously.
-- @param on_done function|nil Optional callback called after update completes.
local function update_decks_view(on_done)
	utils.async_safe_call(ankiconnect.deck_names, nil, function(deck_names, error)
		if error or not deck_names then
			if on_done then
				on_done()
			end
			return
		end
		anki_state.ui.decks = deck_names
		vim.schedule(function()
			if anki_state.ui.deck_buf_id and vim.api.nvim_buf_is_valid(anki_state.ui.deck_buf_id) then
				vim.api.nvim_buf_set_lines(anki_state.ui.deck_buf_id, 0, -1, false, deck_names)
			end
			if on_done then
				on_done()
			end
		end)
	end)
end

--- Refreshes the note buffer based on the current deck filter asynchronously.
-- @param on_done function|nil Optional callback called after refresh completes.
local function update_notes_view(on_done)
	local current_filter = anki_state.ui.current_filter
	local query = current_filter or "deck:*"
	get_notes_for_query(query, function(notes_info)
		vim.schedule(function()
			display_notes_in_buffer(notes_info, query)
			if on_done then
				on_done()
			end
		end)
	end)
end

--- Refreshes both the deck and note buffers asynchronously.
function M.refresh_all()
	update_decks_view(function()
		update_notes_view()
	end)
end

--- Refreshes the deck buffer asynchronously.
function M.refresh_decks()
	update_decks_view()
end

--- Refreshes the note buffer asynchronously.
function M.refresh_notes()
	update_notes_view()
end

--- Shows all notes, ignoring any deck filter, asynchronously.
function M.show_all_notes()
	get_notes_for_query("deck:*", function(notes_info)
		vim.schedule(function()
			display_notes_in_buffer(notes_info, nil)
		end)
	end)
end

--- Updates the note buffer based on the currently selected deck asynchronously.
function M.select_deck()
	local line = vim.api.nvim_get_current_line()
	local deck_name = line
	if deck_name then
		local query = string.format('"deck:%s"', utils.escape_search_query(deck_name))
		get_notes_for_query(query, function(notes_info)
			vim.schedule(function()
				display_notes_in_buffer(notes_info, query)
			end)
		end)
	end
end

--- Opens the Anki UI, creating windows and initializing state.
function M.open()
	local windows = require("anki.ui.windows")

	if windows.focus_existing_window() then
		return
	end

	windows.check_anki_permissions(ankiconnect, function(granted)
		if not granted then
			return
		end

		vim.schedule(function()
			local deck_win_id = windows.create_layout()
			windows.setup_deck_keymaps(anki_state.ui.deck_buf_id)
			windows.setup_note_keymaps(anki_state.ui.note_buf_id)

			anki_state.ui.current_filter = "deck:*"
			update_decks_view(function()
				update_notes_view()
			end)

			anki_state.ui.win_id = deck_win_id

			editor.setup_editor_quit_keybinding()
		end)
	end)
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
