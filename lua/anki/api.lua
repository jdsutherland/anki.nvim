---
--- anki.api
---
--- Provides functions to send, pull, and delete notes in Anki via AnkiConnect.
--- Handles communication between the Neovim UI and the AnkiConnect API.
---
---
--- anki.api
---
--- Provides functions to send, pull, and delete notes in Anki via AnkiConnect.
--- Handles communication between the Neovim UI and the AnkiConnect API.
---
local config = require("anki.config")
local ankiconnect = require("anki.ankiconnect")
local anki_state = require("anki.state")
local notification = require("anki.notification")
local utils = require("anki.utils")
local editor = require("anki.editor")
local operations = require("anki.ui.operations")

local M = {}

--- Checks if a note with the given ID exists in Anki.
-- @param note_id any The note ID to check.
-- @return boolean True if the note exists, false otherwise.
local function validate_note_exists(note_id)
	if not note_id then
		return false
	end
	local query = string.format("nid:%s", note_id)
	local result_notes = utils.safe_call(ankiconnect.find_notes, query)
	if not result_notes then
		return false
	end
	return #result_notes > 0
end

--- Checks if a note can be added to Anki with the given parameters.
-- @param deck_name string The deck name.
-- @param model_name string The model name.
-- @param fields table The note fields.
-- @param tags table The note tags.
-- @return boolean True if the note can be added, false otherwise.
local function can_add_note(deck_name, model_name, fields, tags)
	local validation_result =
		utils.safe_call(ankiconnect.can_add_notes_with_error_details, deck_name, model_name, fields, tags)
	return validation_result and validation_result[1] and validation_result[1].canAdd
end

--- Handles opening the Anki GUI browser for a note, optionally updating it.
-- @param note table The note object.
-- @param is_new boolean Whether the note is new.
-- @param fields table The note fields.
-- @param tags table The note tags.
local function handle_gui_browse(note, is_new, fields, tags)
	if not config.options.gui_browse_enabled then
		return
	end

	if is_new then
		local query = string.format('"deck:%s" nid:%s', note.deck_name, note.id)
		utils.safe_call(ankiconnect.gui_browse, query)
	else
		utils.safe_call(ankiconnect.gui_browse, "nid:1")
		utils.safe_call(ankiconnect.update_note, note.id, fields, tags)
		local query = string.format('"deck:%s" nid:%s', note.deck_name, note.id)
		utils.safe_call(ankiconnect.gui_browse, query)
	end
end

--- Notifies the user whether a note was added or updated.
-- @param is_new boolean True if the note was added, false if updated.
local function notify_user(is_new)
	notification.info(is_new and "Note added" or "Note updated")
end

--- Uploads all pending media attachments for a note via storeMediaFile.
--- Used for update_note which doesn't support inline media params.
-- @param note table The note object with media attachments.
local function upload_note_media(note)
	if not note.media then
		return
	end
	for _, entry in ipairs(note.media.picture or {}) do
		if entry.path then
			utils.safe_call(ankiconnect.store_media_file, entry.filename, { path = entry.path })
		elseif entry.url then
			utils.safe_call(ankiconnect.store_media_file, entry.filename, { url = entry.url })
		elseif entry.data then
			utils.safe_call(ankiconnect.store_media_file, entry.filename, { data = entry.data })
		end
	end
	for _, entry in ipairs(note.media.audio or {}) do
		if entry.path then
			utils.safe_call(ankiconnect.store_media_file, entry.filename, { path = entry.path })
		elseif entry.url then
			utils.safe_call(ankiconnect.store_media_file, entry.filename, { url = entry.url })
		elseif entry.data then
			utils.safe_call(ankiconnect.store_media_file, entry.filename, { data = entry.data })
		end
	end
	for _, entry in ipairs(note.media.video or {}) do
		if entry.path then
			utils.safe_call(ankiconnect.store_media_file, entry.filename, { path = entry.path })
		elseif entry.url then
			utils.safe_call(ankiconnect.store_media_file, entry.filename, { url = entry.url })
		elseif entry.data then
			utils.safe_call(ankiconnect.store_media_file, entry.filename, { data = entry.data })
		end
	end
end

--- Sends the current note to Anki, adding or updating as needed.
-- @param bufnr number The buffer number of the note.
-- @param kill boolean|nil Whether to kill the note buffer after sending.
M.send_note = function(bufnr, kill)
	if type(bufnr) ~= "number" then
		error("[anki.nvim][api] send_note: bufnr must be a number")
	end
	if kill ~= nil and type(kill) ~= "boolean" then
		error("[anki.nvim][api] send_note: kill must be a boolean or nil")
	end
	local found = editor.search_for_note(bufnr)
	if not found then
		notification.warn("[anki.nvim][api] No Anki note buffer found")
		return
	end

	local note_to_send = anki_state.current_note
	local content = note_to_send:get_content_from_buffers()
	local fields = content.fields
	local tags = content.tags
	local is_new_note = note_to_send.id == nil

	if note_to_send.id and not validate_note_exists(note_to_send.id) then
		note_to_send.id = nil
		is_new_note = true
	end

	local can_add = can_add_note(note_to_send.deck_name, note_to_send.model_name, fields, tags)

	if is_new_note then
		if not can_add then
			notification.error("[anki.nvim][api] The note already exists but its ID is unknown by anki.nvim")
			return
		end

		local has_media = #note_to_send.media.picture > 0
			or #note_to_send.media.audio > 0
			or #note_to_send.media.video > 0

		local result_note_id
		if has_media then
			result_note_id = utils.safe_call(
				ankiconnect.add_note,
				note_to_send.deck_name,
				note_to_send.model_name,
				fields,
				tags,
				note_to_send.media
			)
		else
			result_note_id =
				utils.safe_call(ankiconnect.add_note, note_to_send.deck_name, note_to_send.model_name, fields, tags)
		end

		if not result_note_id then
			notification.error("[anki.nvim][api] Failed to add note to Anki (no note ID returned)")
			return
		end

		note_to_send.id = result_note_id
		handle_gui_browse(note_to_send, true, fields, tags)
	else
		-- For existing notes, upload any pending media via storeMediaFile
		-- since updateNote doesn't support inline media params
		upload_note_media(note_to_send)
		handle_gui_browse(note_to_send, false, fields, tags)
		utils.safe_call(ankiconnect.update_note, note_to_send.id, fields, tags)
	end

	-- Cleanup if requested
	if kill then
		editor.delete_note_buffers(note_to_send)
		anki_state.current_note = nil
	end

	notify_user(is_new_note)
	operations.refresh_all()
end

--- Pulls the latest content for the current note from Anki into the buffers.
-- @param bufnr number The buffer number of the note.
M.pull_note = function(bufnr)
	if type(bufnr) ~= "number" then
		error("[anki.nvim][api] pull_note: bufnr must be a number")
	end
	local found = editor.search_for_note(bufnr)
	if not found then
		notification.warn("[anki.nvim][api] No Anki note buffer found")
		return
	end

	local note_to_pull = anki_state.current_note
	if not note_to_pull.id then
		notification.error("[anki.nvim][api] Cannot pull note, it was not sent to Anki yet")
		return
	end

	local notes_data = utils.safe_call(ankiconnect.notes_info, { note_to_pull.id })
	if not notes_data then
		notification.error("[anki.nvim][api] Failed to fetch note info from Anki")
		return
	end
	local first_note = notes_data[1]

	vim.api.nvim_buf_set_lines(note_to_pull.tags.bufnr, 0, -1, false, first_note.tags)

	for key, field in pairs(first_note.fields) do
		local field_found_in_note = note_to_pull:find_field_by_name(key)
		if field_found_in_note then
			vim.api.nvim_buf_set_lines(
				note_to_pull.fields[field_found_in_note].editor_context.bufnr,
				0,
				-1,
				false,
				utils.split(field.value, "\n")
			)
		end
	end
	notification.info("[anki.nvim][api] Note pulled from Anki")
end

--- Deletes the current note from Anki and updates the UI.
-- @param bufnr number The buffer number of the note.
M.delete_note = function(bufnr)
	if type(bufnr) ~= "number" then
		error("[anki.nvim][api] delete_note: bufnr must be a number")
	end
	local found = editor.search_for_note(bufnr)
	if not found then
		notification.warn("[anki.nvim][api] No Anki note buffer found")
		return
	end

	local note_to_delete = anki_state.current_note
	if note_to_delete.id == nil then
		notification.warn("[anki.nvim][api] Cannot delete note, it was not sent to Anki yet")
		return
	end

	local result = utils.safe_call(ankiconnect.delete_notes, { note_to_delete.id })
	if result == nil then
		notification.error("[anki.nvim][api] Failed to delete note from Anki")
		return
	end
	note_to_delete.id = nil
	notification.info("[anki.nvim][api] Note deleted")

	if config.options.gui_browse_enabled then
		local query = string.format('"deck:%s"', note_to_delete.deck_name)
		utils.safe_call(ankiconnect.gui_browse, query)
	end
	operations.refresh_all()
end

return M
