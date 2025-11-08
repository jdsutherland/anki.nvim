---
--- anki.editor
---
--- Provides functions for creating, displaying, and managing Anki notes and their buffers/windows in Neovim.
--- Handles editor window layout, buffer management, and note state.
---
local anki_state = require("anki.state")
local EditorContext = require("anki.classes.editor_context")
local Field = require("anki.classes.field")
local Note = require("anki.classes.note")
local notification = require("anki.notification")
local config = require("anki.config")

local M = {}

--- Creates a new note object with the given deck, model, and fields.
-- @param deck_name string The name of the deck.
-- @param model_name string The name of the model.
-- @param field_names table List of field names.
-- @param id any Optional note ID.
-- @return table The created note object.
function M.create_note(deck_name, model_name, field_names, id)
	if type(deck_name) ~= "string" then
		error("[anki.nvim][editor] create_note: deck_name must be a string")
	end
	if type(model_name) ~= "string" then
		error("[anki.nvim][editor] create_note: model_name must be a string")
	end
	if type(field_names) ~= "table" then
		error("[anki.nvim][editor] create_note: field_names must be a table")
	end
	local fields = {}

	for _, name in pairs(field_names) do
		table.insert(
			fields,
			Field:new({
				editor_context = EditorContext:new({
					winid = vim.api.nvim_get_current_win(),
					tabid = vim.api.nvim_get_current_tabpage(),
					bufnr = vim.api.nvim_create_buf(true, true),
				}),
				name = name,
			})
		)
	end

	local note = Note:new({
		fields = fields,
		tags = EditorContext:new({
			winid = vim.api.nvim_get_current_win(),
			tabid = vim.api.nvim_get_current_tabpage(),
			bufnr = vim.api.nvim_create_buf(true, true),
		}),
		deck_name = deck_name,
		model_name = model_name,
		id = id,
	})

	anki_state.current_note = note

	return note
end

--- Displays the given note in the editor window, setting up splits and keymaps.
-- @param note table The note object to display.
function M.display_note(note)
	if type(note) ~= "table" then
		error("[anki.nvim][editor] display_note: note must be a table")
	end
	anki_state.counter = anki_state.counter + 1

	local editor_win_id = anki_state.ui.editor_win_id
	if not editor_win_id or not vim.api.nvim_win_is_valid(editor_win_id) then
		vim.cmd("vnew")
		editor_win_id = vim.api.nvim_get_current_win()
		anki_state.ui.editor_win_id = editor_win_id
	end

	vim.api.nvim_set_current_win(editor_win_id)
	local new_tabid = vim.api.nvim_win_get_tabpage(editor_win_id)

	note.tags.winid = editor_win_id
	note.tags.tabid = new_tabid

	local counter = anki_state.counter
	vim.api.nvim_buf_set_name(note.tags.bufnr, "anki://Tags_" .. counter)
	vim.api.nvim_win_set_buf(editor_win_id, note.tags.bufnr)

	local bufnrs = { note.tags.bufnr }
	for _, field in ipairs(note.fields) do
		table.insert(bufnrs, field.editor_context.bufnr)
	end

	for _, bufnr in ipairs(bufnrs) do
		local mappings = {
			send_note = string.format("<Cmd>lua require('anki.api').send_note(%d)<CR>", bufnr),
			pull_note = string.format("<Cmd>lua require('anki.api').pull_note(%d)<CR>", bufnr),
			delete_note = string.format("<Cmd>lua require('anki.api').delete_note(%d)<CR>", bufnr),
			kill_note = string.format("<Cmd>lua require('anki.editor').kill_note(%d)<CR>", bufnr),
			show_help = string.format("<Cmd>lua require('anki.ui.help').show_help('editor')<CR>"),
		}

		for action, key in pairs(config.options.mappings.editor) do
			if mappings[action] then
				vim.api.nvim_buf_set_keymap(bufnr, "n", key, mappings[action], { noremap = true, silent = true })
			end
		end
	end

	for i = #note.fields, 1, -1 do
		vim.cmd("split")
		local new_win = vim.api.nvim_get_current_win()
		vim.api.nvim_set_option_value("filetype", "html", { buf = note.fields[i].editor_context.bufnr })
		vim.api.nvim_buf_set_name(
			note.fields[i].editor_context.bufnr,
			"anki://" .. note.fields[i].name .. "_" .. counter
		)
		vim.api.nvim_win_set_buf(new_win, note.fields[i].editor_context.bufnr)

		note.fields[i].editor_context.winid = new_win
		note.fields[i].editor_context.tabid = new_tabid
	end
end

--- Searches for a note buffer by buffer number.
-- @param bufnr number The buffer number to search for.
-- @return number|nil 1 if found, nil otherwise.
function M.search_for_note(bufnr)
	if type(bufnr) ~= "number" then
		error("[anki.nvim][editor] search_for_note: bufnr must be a number")
	end
	if anki_state.current_note == nil then
		return nil
	end

	if anki_state.current_note.tags.bufnr == bufnr then
		return 1
	end

	for _, field in ipairs(anki_state.current_note.fields) do
		if field.editor_context.bufnr == bufnr then
			return 1
		end
	end

	return nil
end

--- Deletes all buffers and windows associated with a note.
-- @param note table The note object whose buffers should be deleted.
function M.delete_note_buffers(note)
	if type(note) ~= "table" then
		error("[anki.nvim][editor] delete_note_buffers: note must be a table")
	end
	local survivor_win_id = anki_state.ui.editor_win_id
	local windows_to_close = {}

	if vim.api.nvim_win_is_valid(note.tags.winid) then
		table.insert(windows_to_close, note.tags.winid)
	end
	for _, field in ipairs(note.fields) do
		if vim.api.nvim_win_is_valid(field.editor_context.winid) then
			table.insert(windows_to_close, field.editor_context.winid)
		end
	end

	-- Close all 'child' splits, leaving the main editor pane
	for _, win_id in ipairs(windows_to_close) do
		if win_id ~= survivor_win_id then
			vim.api.nvim_win_close(win_id, true)
		end
	end

	if survivor_win_id and vim.api.nvim_win_is_valid(survivor_win_id) then
		local empty_buf = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_win_set_buf(survivor_win_id, empty_buf)
		M.setup_editor_quit_keybinding()
	end

	-- Now that no windows are displaying them, delete the note's buffers
	vim.api.nvim_buf_delete(note.tags.bufnr, { force = true })
	for _, field in pairs(note.fields) do
		vim.api.nvim_buf_delete(field.editor_context.bufnr, { force = true })
	end
end

--- Kills (closes) the note buffer associated with the given buffer number.
-- @param bufnr number The buffer number to kill.
function M.kill_note(bufnr)
	local found = M.search_for_note(bufnr)
	if not found then
		notification.warn("No Anki note buffer found")
		return
	end

	local note_to_kill = anki_state.current_note

	M.delete_note_buffers(note_to_kill)

	anki_state.current_note = nil
	notification.info("Note buffers killed")

	M.setup_editor_quit_keybinding()
end

--- Kills (closes) all active note buffers and cleans up state.
function M.kill_all()
	if anki_state.current_note == nil then
		notification.info("No active Anki notes to clean up.")
		return
	end

	M.delete_note_buffers(anki_state.current_note)

	anki_state.current_note = nil
	notification.info("Cleaned up current Anki note.")

	M.setup_editor_quit_keybinding()
end

--- Sets up the 'q' keybinding in the editor window to allow quitting if no note is open.
function M.setup_editor_quit_keybinding()
	local editor_win_id = anki_state.ui.editor_win_id
	if not editor_win_id or not vim.api.nvim_win_is_valid(editor_win_id) then
		return
	end

	-- Only allow quit if no note is currently open
	if anki_state.current_note ~= nil then
		return
	end

	local current_bufnr = vim.api.nvim_win_get_buf(editor_win_id)

	vim.api.nvim_buf_set_keymap(
		current_bufnr,
		"n",
		"q",
		"<Cmd>lua require('anki.ui.operations').close()<CR>",
		{ noremap = true, silent = true }
	)
end

return M
