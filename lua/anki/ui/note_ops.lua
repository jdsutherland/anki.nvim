local utils = require("anki.utils")
local ankiconnect = require("anki.ankiconnect")
local anki_state = require("anki.state")
local editor = require("anki.editor")
local operations = require("anki.ui.operations")
local api = require("anki.api")
local notification = require("anki.notification")

local M = {}

--- Adds a new note to the specified deck, prompting for model and fields if needed.
-- @param deck_name string|nil The name of the deck to add the note to. If nil, uses the current line.
function M.add_note(deck_name)
	if not deck_name then
		deck_name = vim.api.nvim_get_current_line()
	end
	if not deck_name then
		return
	end

	local model_names = utils.safe_call(ankiconnect.model_names)
	if not model_names then
		return
	end

	vim.ui.select(model_names, { prompt = "Select a model" }, function(model_name)
		if not model_name then
			return
		end
		local field_names = utils.safe_call(ankiconnect.model_field_names, model_name)
		if not field_names then
			return
		end
		local note = editor.create_note(deck_name, model_name, field_names)
		editor.display_note(note)
		operations.refresh_all()
	end)
end

--- Edits the note at the current cursor line, handling unsaved changes if another note is open.
function M.edit_note()
	local line_num = vim.api.nvim_win_get_cursor(0)[1]
	local note = anki_state.ui.notes[line_num]
	if not note then
		return
	end

	if anki_state.current_note then
		vim.ui.input({ prompt = "Save changes to current note before opening new one? (Y/n)" }, function(input)
			if input == "Y" or input == "y" then
				api.send_note(anki_state.current_note.tags.bufnr)
			end
			M.switch_to_new_note(note)
			operations.refresh_all()
		end)
	else
		M.switch_to_new_note(note)
		operations.refresh_all()
	end
end

--- Switches the editor context to a new note, cleaning up the previous note if needed.
-- @param note table The note object to switch to.
function M.switch_to_new_note(note)
	if anki_state.current_note then
		editor.delete_note_buffers(anki_state.current_note)
	end

	-- Optimize field sorting using built-in table operations
	local sorted_fields = {}
	for key, field in pairs(note.fields) do
		sorted_fields[field.order + 1] = {
			value = field.value,
			name = key,
		}
	end

	-- Extract field names efficiently
	local fields_names = {}
	for i = 1, #sorted_fields do
		if sorted_fields[i] then
			table.insert(fields_names, sorted_fields[i].name)
		end
	end

	local deck_win_id = vim.fn.bufwinid(anki_state.ui.deck_buf_id)
	local cursor_line = vim.api.nvim_win_get_cursor(deck_win_id)[1]
	local deck_name = vim.api.nvim_buf_get_lines(anki_state.ui.deck_buf_id, cursor_line - 1, cursor_line, true)[1]

	local new_note = editor.create_note(deck_name, note.modelName, fields_names, note.noteId)

	vim.api.nvim_buf_set_lines(new_note.tags.bufnr, 0, -1, false, note.tags)

	for i, field_data in ipairs(sorted_fields) do
		if field_data then
			vim.api.nvim_buf_set_lines(
				new_note.fields[i].editor_context.bufnr,
				0,
				-1,
				false,
				utils.split(field_data.value, "\n")
			)
		end
	end

	editor.display_note(new_note)
end

--- Deletes the note at the current cursor line after user confirmation.
function M.delete_note()
	local line_num = vim.api.nvim_win_get_cursor(0)[1]
	local note = anki_state.ui.notes[line_num]
	if not note then
		return
	end

	vim.ui.input({ prompt = "Are you sure you want to delete this note? (Y/n)" }, function(input)
		if input == "Y" or input == "y" then
			local result = utils.safe_call(ankiconnect.delete_notes, { note.noteId })
			if result == nil then
				notification.error("[anki.nvim][note_ops] Failed to delete note.")
				return
			end
			operations.refresh_all()
		end
	end)
end

--- Opens the GUI browser for the note at the current cursor line in Anki.
function M.gui_note()
	local line_num = vim.api.nvim_win_get_cursor(0)[1]
	local note = anki_state.ui.notes[line_num]
	if not note then
		return
	end
	local query = string.format("nid:%s", note.noteId)
	utils.safe_call(ankiconnect.gui_browse, query)
end

---
--- Move selected note(s) to another deck (supports normal and visual mode)
---
--- Moves the selected note(s) to another deck, supporting both normal and visual mode selection.
function M.move_note_to_deck()
	local mode = vim.fn.mode()
	local start_line, end_line
	if mode == "v" or mode == "V" or mode == "\22" then -- visual/visual-line/block
		start_line = vim.fn.line("v")
		end_line = vim.fn.line(".")
		if start_line > end_line then
			start_line, end_line = end_line, start_line
		end
	else
		start_line = vim.api.nvim_win_get_cursor(0)[1]
		end_line = start_line
	end

	local notes = {}
	for i = start_line, end_line do
		local note = anki_state.ui.notes[i]
		if note then
			table.insert(notes, note)
		end
	end
	if #notes == 0 then
		notification.warn("[anki.nvim][note_ops] No notes selected.")
		return
	end

	local deck_names = utils.safe_call(ankiconnect.deck_names)
	if not deck_names or #deck_names == 0 then
		notification.error("[anki.nvim][note_ops] Could not fetch deck names.")
		return
	end
	vim.ui.select(deck_names, { prompt = "Move to which deck?" }, function(target_deck)
		if not target_deck then
			return
		end
		local note_ids = {}
		for _, note in ipairs(notes) do
			table.insert(note_ids, note.noteId)
		end
		local notes_info = utils.safe_call(ankiconnect.notes_info, note_ids)
		if not notes_info then
			notification.error("[anki.nvim][note_ops] Could not fetch note info.")
			return
		end
		local card_ids = {}
		for _, info in ipairs(notes_info) do
			if info.cards then
				for _, cid in ipairs(info.cards) do
					table.insert(card_ids, cid)
				end
			end
		end
		if #card_ids == 0 then
			notification.warn("[anki.nvim][note_ops] No cards found for selected notes.")
			return
		end
		local result = utils.safe_call(ankiconnect.change_deck, card_ids, target_deck)
		if result == nil then
			notification.error("[anki.nvim][note_ops] Failed to move cards to deck " .. target_deck)
			return
		end
		notification.info(
			"[anki.nvim][note_ops] Moved " .. tostring(#card_ids) .. " card(s) to deck '" .. target_deck .. "'."
		)
		operations.refresh_notes()
	end)
end

return M
