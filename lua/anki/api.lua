local config = require("anki.config")
local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local conf = require("telescope.config").values
local ankiconnect = require("anki.ankiconnect")
local anki_state = require("anki.state")
local classes = require("anki.classes")
local notification = require("anki.notification")
local utils = require("anki.utils")
local editor = require("anki.editor")
local anki_pickers = require("anki.pickers")

local M = {}

M.add_note = function(arguments)
	arguments = arguments or {}
	local opts = arguments.opts or {}
	local display = arguments.display or nil

	local result_deck_names = utils.safe_call(ankiconnect.deck_names)
	if not result_deck_names then
		return
	end
	local result_model_names = utils.safe_call(ankiconnect.model_names)
	if not result_model_names then
		return
	end
	anki_pickers.pick_one("decks", result_deck_names, opts, function(deck_selection)
		anki_pickers.pick_one("models", result_model_names, opts, function(model_selection)
			local result_field_names = utils.safe_call(ankiconnect.model_field_names, model_selection[1])
			if not result_field_names then
				return
			end
			local note = editor.create_note(deck_selection[1], model_selection[1], result_field_names, display)
			editor.display_note(note, display)
		end)
	end)
end

M.add_note_to_quick_deck = function(arguments)
	arguments = arguments or {}
	local opts = arguments.opts or {}
	local display = arguments.display or nil

	if not anki_state.quickdeck then
		return
	end

	local result_model_names = utils.safe_call(ankiconnect.model_names)
	if not result_model_names then
		return
	end

	anki_pickers.pick_one("models", result_model_names, opts, function(model_selection)
		local result_field_names = utils.safe_call(ankiconnect.model_field_names, model_selection[1])
		if not result_field_names then
			return
		end
		local note = editor.create_note(anki_state.quickdeck, model_selection[1], result_field_names, display)
		editor.display_note(note, display)
	end)
end

M.select_state_quickdeck = function(opts)
	opts = opts or {}
	local result_deck_names = utils.safe_call(ankiconnect.deck_names)
	if not result_deck_names then
		return
	end
	anki_pickers.pick_one("decks", result_deck_names, opts, function(deck_selection)
		anki_state.quickdeck = deck_selection[1]
	end)
end

M.edit_note_from_quick_deck = function(arguments)
	arguments = arguments or {}
	local opts = arguments.opts or {}
	local display = arguments.display or nil

	if not anki_state.quickdeck then
		return
	end
	local query = string.format('"deck:%s"', anki_state.quickdeck)
	local result_notes_ids = utils.safe_call(ankiconnect.find_notes, query)
	if not result_notes_ids then
		return
	end
	local result_notes_info = utils.safe_call(ankiconnect.notes_info, result_notes_ids)
	if not result_notes_info then
		return
	end

	if next(result_notes_info) == nil then
		notification.warn("Deck is empty: " .. anki_state.quickdeck)
		return
	end

	anki_pickers.pick_one("notes", result_notes_info, opts, function(note_selection)
		local sorted_fields = {}

		for i = 0, utils.table_length(note_selection.value.fields) do
			sorted_fields[(i + 1)] = nil
		end

		for key, field in pairs(note_selection.value.fields) do
			table.insert(sorted_fields, (field.order + 1), {
				value = field.value,
				name = key,
			})
		end

		local fields_names = {}
		for key, field in pairs(sorted_fields) do
			table.insert(fields_names, field.name)
		end

		local note = editor.create_note(
			anki_state.quickdeck,
			note_selection.value.modelName,
			fields_names,
			display,
			note_selection.value.noteId
		)

		-- Set the content of the tags buffers
		vim.api.nvim_buf_set_lines(note.tags.bufnr, 0, -1, false, note_selection.value.tags)

		-- Set the content of the fields buffers
		for i, v in pairs(sorted_fields) do
			vim.api.nvim_buf_set_lines(note.fields[i].editor_context.bufnr, 0, -1, false, utils.split(v.value, "\n"))
		end

		editor.display_note(note, display)
	end, anki_pickers.note_entry_maker)
end

M.kill_note = function(bufnr)
	editor.kill_note(bufnr)
end

M.kill_all = function()
	editor.kill_all()
end

M.send_note = function(bufnr, kill)
	kill = kill or nil
	local found = editor.search_for_note(bufnr)
	if not found then
		notification.warn("No Anki note buffer found")
		return
	end

	local note_to_send = anki_state.notes[found]

	local content = note_to_send:get_content_from_buffers()
	local fields = content.fields
	local tags = content.tags

	local msg_status = (note_to_send.id == nil) or false and true

	-- Make sure the note stil exists in anki
	if note_to_send.id then
		local query = string.format("nid:%s", note_to_send.id)
		local result_notes = utils.safe_call(ankiconnect.find_notes, query)
		if not result_notes then
			return
		end
		if #result_notes == 0 then
			note_to_send.id = nil
			anki_state.notes[found].id = nil
		end
	end

	local can_add_note = true

	-- Make sure we can add the note
	local result_can_add_note = utils.safe_call(
		ankiconnect.can_add_notes_with_error_details,
		note_to_send.deck_name,
		note_to_send.model_name,
		fields,
		tags
	)
	if not result_can_add_note then
		return
	end

	if result_can_add_note[1].canAdd then
		can_add_note = true
	end

	if note_to_send.id == nil and can_add_note == false then
		notification.error("The note already exists but its ID is unknown by anki.nvim")
		return
	end

	if note_to_send.id == nil and can_add_note then
		local result_note_id =
			utils.safe_call(ankiconnect.add_note, note_to_send.deck_name, note_to_send.model_name, fields, tags)
		if not result_note_id then
			return
		end

		note_to_send.id = result_note_id

		if config.options.gui_browse_enabled then
			local query = string.format('"deck:%s" nid:%s', note_to_send.deck_name, note_to_send.id)
			utils.safe_call(ankiconnect.gui_browse, query)
		end
	else
		-- https://github.com/FooSoft/anki-connect/issues/82#issuecomment-1221895385
		if config.options.gui_browse_enabled then
			local query = "nid:1"
			utils.safe_call(ankiconnect.gui_browse, query)
		end

		local _ = utils.safe_call(ankiconnect.update_note, note_to_send.id, fields, tags)

		if config.options.gui_browse_enabled then
			local query = string.format('"deck:%s" nid:%s', note_to_send.deck_name, note_to_send.id)
			utils.safe_call(ankiconnect.gui_browse, query)
		end
	end

	if kill then
		editor.delete_note_buffers(note_to_send)
		table.remove(anki_state.notes, found)
	end

	if msg_status then
		notification.info("Note added")
	else
		notification.info("Note updated")
	end
end

M.edit_note = function(arguments)
	arguments = arguments or {}
	local opts = arguments.opts or {}
	local display = arguments.display or nil

	local result_deck_names = utils.safe_call(ankiconnect.deck_names)
	if not result_deck_names then
		return
	end

	anki_pickers.pick_one("decks", result_deck_names, opts, function(deck_selection)
		local query = string.format('"deck:%s"', deck_selection[1])

		local result_find_notes = utils.safe_call(ankiconnect.find_notes, query)
		if not result_find_notes then
			return
		end
		local result_deck_notes_info = utils.safe_call(ankiconnect.notes_info, result_find_notes)
		if not result_deck_notes_info then
			return
		end

		if next(result_deck_notes_info) == nil then
			notification.warn("Deck is empty: " .. deck_selection[1])
			return
		end

		anki_pickers.pick_one("notes", result_deck_notes_info, opts, function(note_selection)
			local sorted_fields = {}
			-- Initialize table
			for i = 0, utils.table_length(note_selection.value.fields) do
				sorted_fields[(i + 1)] = nil
			end
			for key, field in pairs(note_selection.value.fields) do
				table.insert(sorted_fields, (field.order + 1), {
					value = field.value,
					name = key,
				})
			end

			local fields_names = {}
			for key, field in pairs(sorted_fields) do
				table.insert(fields_names, field.name)
			end

			local note = editor.create_note(
				deck_selection[1],
				note_selection.value.modelName,
				fields_names,
				display,
				note_selection.value.noteId
			)

			-- Set the content of the tags buffers
			vim.api.nvim_buf_set_lines(note.tags.bufnr, 0, -1, false, note_selection.value.tags)

			-- Set the content of the fields buffers
			for i, _ in ipairs(sorted_fields) do
				vim.api.nvim_buf_set_lines(
					note.fields[i].editor_context.bufnr,
					0,
					-1,
					false,
					utils.split(sorted_fields[i].value, "\n")
				)
			end

			editor.display_note(note, display)
		end, anki_pickers.note_entry_maker)
	end)
end

M.pull_note = function(bufnr)
	local found = editor.search_for_note(bufnr)
	if not found then
		notification.warn("No Anki note buffer found")
		return
	end
	local note_to_pull = anki_state.notes[found]
	if not note_to_pull.id then
		notification.error("Cannot pull note, it was not sent to Anki yet")
		return
	end

	-- get the note infos
	local result_notes_info = utils.safe_call(ankiconnect.notes_info, { note_to_pull.id })
	if not result_notes_info then
		return
	end
	local first_note = result_notes_info[1]

	-- Set the content of the tags buffers
	vim.api.nvim_buf_set_lines(note_to_pull.tags.bufnr, 0, -1, false, first_note.tags)

	-- Set the content of the fields buffers
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
	notification.info("Note pulled from Anki")
end

M.delete_note = function(bufnr)
	local found = editor.search_for_note(bufnr)
	if not found then
		notification.warn("No Anki note buffer found")
		return
	end
	local note_to_delete = anki_state.notes[found]
	if note_to_delete.id == nil then
		notification.warn("Cannot delete note, it was not sent to Anki yet")
		return
	end

	local _ = utils.safe_call(ankiconnect.delete_notes, { note_to_delete.id })
	note_to_delete.id = nil
	notification.info("Note deleted")

	if config.options.gui_browse_enabled then
		local query = string.format('"deck:%s"', note_to_delete.deck_name)
		utils.safe_call(ankiconnect.gui_browse, query)
	end
end

M.pick_delete_notes = function(opts)
	local result_deck_names = utils.safe_call(ankiconnect.deck_names)
	if not result_deck_names then
		return
	end

	anki_pickers.pick_one("decks", result_deck_names, opts, function(deck_selection)
		local query = string.format('"deck:%s"', deck_selection[1])
		local result_find_notes = utils.safe_call(ankiconnect.find_notes, query)
		if not result_find_notes then
			return
		end
		local result_deck_notes_info = utils.safe_call(ankiconnect.notes_info, result_find_notes)
		if not result_deck_notes_info then
			return
		end

		if next(result_deck_notes_info) == nil then
			notification.warn("Deck is empty: " .. deck_selection[1])
			return
		end

		anki_pickers.pick_one_or_multi("notes", result_deck_notes_info, opts, function(note_selection)
			local note_id_to_delete = note_selection.value.noteId
			local _ = utils.safe_call(ankiconnect.delete_notes, { note_id_to_delete })
			notification.info("Note deleted")
			if config.options.gui_browse_enabled then
				local query = string.format('"deck:%s"', deck_selection[1])
				utils.safe_call(ankiconnect.gui_browse, query)
			end
		end, function(multi)
			for _, note in ipairs(multi) do
				local note_id_to_delete = note.value.noteId
				local _ = utils.safe_call(ankiconnect.delete_notes, { note_id_to_delete })
			end
			notification.info("Deleted " .. #multi .. " note(s)")
			if config.options.gui_browse_enabled then
				local query = string.format('"deck:%s"', deck_selection[1])
				utils.safe_call(ankiconnect.gui_browse, query)
			end
		end, anki_pickers.note_entry_maker)
	end)
end

M.pick_notes_to_delete_from_quick_deck = function(opts)
	if not anki_state.quickdeck then
		return
	end
	local query = string.format('"deck:%s"', anki_state.quickdeck)

	local result_find_notes = utils.safe_call(ankiconnect.find_notes, query)
	if not result_find_notes then
		return
	end
	local result_deck_notes_info = utils.safe_call(ankiconnect.notes_info, result_find_notes)
	if not result_deck_notes_info then
		return
	end

	if next(result_deck_notes_info) == nil then
		notification.warn("Deck is empty: " .. anki_state.quickdeck)
		return
	end

	anki_pickers.pick_one_or_multi("notes", result_deck_notes_info, opts, function(note_selection)
		local note_id_to_delete = note_selection.value.noteId

		local _ = utils.safe_call(ankiconnect.delete_notes, { note_id_to_delete })
		notification.info("Note deleted")
		if config.options.gui_browse_enabled then
			local query = string.format('"deck:%s"', anki_state.quickdeck)
			utils.safe_call(ankiconnect.gui_browse, query)
		end
	end, function(multi)
		for _, note in ipairs(multi) do
			local note_id_to_delete = note.value.noteId
			local _ = utils.safe_call(ankiconnect.delete_notes, { note_id_to_delete })
		end
		notification.info("Deleted " .. #multi .. " note(s)")
		if config.options.gui_browse_enabled then
			local query = string.format('"deck:%s"', anki_state.quickdeck)
			utils.safe_call(ankiconnect.gui_browse, query)
		end
	end, anki_pickers.note_entry_maker)
end

M.infos = function()
	local infos_bufnr = vim.api.nvim_create_buf(false, true)
	-- Add the buffer mappings
	vim.api.nvim_buf_set_keymap(infos_bufnr, "n", "q", "<Cmd>bd!<CR>", { noremap = true, silent = true })

	local found = editor.search_for_note(vim.api.nvim_get_current_buf())
	local current_note = nil
	if found then
		current_note = anki_state.notes[found]
	end

	-- Add the text content
	local content = {
		"--- Configuration",
		"anki_url\t\t\t\t\t\t\t\t\t\t" .. config.options.url,
		"anki_timeout\t\t\t\t\t\t\t\t" .. config.options.timeout,
		"anki_prefix\t\t\t\t\t\t\t\t\t" .. config.options.prefix,
		"anki_default_mappings\t\t\t\t" .. tostring(config.options.default_mappings),
		"anki_quickdeck\t\t\t\t\t\t\t" .. config.options.quickdeck,
		"anki_gui_browse_enabled \t\t" .. tostring(config.options.gui_browse_enabled),
		"anki_custom_display\t\t\t\t\t" .. (config.options.custom_display and tostring(true) or tostring(false)),
		"anki_custom_delete\t\t\t\t\t" .. (config.options.custom_delete and tostring(true) or tostring(false)),
		"anki_after_edit_buffer_hook\t"
			.. (config.options.after_edit_buffer_hook and tostring(true) or tostring(false)),
		"",
		"--- State",
		"quickdeck \t\t\t\t\t\t\t\t\t" .. anki_state.quickdeck,
		"",
		"--- Current Note",
		(function()
			if current_note then
				return "id \t\t\t\t\t\t\t\t\t\t\t\t\t" .. tostring(current_note.id),
					"deck \t\t\t\t\t\t\t\t\t\t\t\t" .. current_note.deck_name,
					"model \t\t\t\t\t\t\t\t\t\t\t" .. current_note.model_name
			else
				return "Not in a note field buffer"
			end
		end)(),
	}
	vim.api.nvim_buf_set_lines(infos_bufnr, 0, -1, false, content)
	local width = 60
	local height = 20
	local infos_win = vim.api.nvim_open_win(infos_bufnr, true, {
		relative = "editor",
		width = width,
		height = height,
		col = (vim.o.columns - width) / 2,
		row = (vim.o.lines - height) / 2,
		anchor = "NW",
		style = "minimal",
		border = "single",
		title = "Anki Infos",
	})
end

M.gui_deck = function()
	local deck = anki_state.quickdeck
	local query = string.format('"deck:%s"', deck)
	utils.safe_call(ankiconnect.gui_browse, query)
end

M.gui_deck_current = function(bufnr)
	local found = editor.search_for_note(bufnr)
	if not found then
		notification.warn("No Anki note buffer found")
		return
	end
	local current_note = anki_state.notes[found]

	local query = string.format('"deck:%s"', current_note.deck_name)
	utils.safe_call(ankiconnect.gui_browse, query)
end

M.gui_note = function(bufnr)
	local found = editor.search_for_note(bufnr)
	if not found then
		notification.warn("No Anki note buffer found")
		return
	end

	local current_note = anki_state.notes[found]

	if not current_note.id then
		notification.warn("Cannot browse to note in GUI, it was not sent to Anki yet")
		return
	end

	local query = string.format("nid:%s", current_note.id)
	utils.safe_call(ankiconnect.gui_browse, query)
end

M.add_deck = function(arguments)
	arguments = arguments or {}
	local opts = arguments.opts or {}

	local deck_names = utils.safe_call(ankiconnect.deck_names)
	if not deck_names then
		return
	end

	pickers
		.new(opts, {
			prompt_title = "Create Deck",
			finder = finders.new_table({
				results = deck_names,
			}),
			sorter = conf.generic_sorter(opts),
			attach_mappings = function(prompt_bufnr, map)
				actions.select_default:replace(function()
					local entry = action_state.get_selected_entry()
					local prompt = action_state.get_current_line()
					actions.close(prompt_bufnr)
					-- Prefer user prompt over entry when available
					local deck_to_create = (prompt and prompt ~= "") and prompt or (entry and entry[1]) or nil
					if not deck_to_create then
						notification.warn("No deck name provided.")
						return
					end
					local deck_id = utils.safe_call(ankiconnect.create_deck, deck_to_create)
					if not deck_id then
						return
					end
					notification.info("Deck created: " .. deck_to_create)
				end)
				return true
			end,
			enable_prompt = true, -- allows free typing
		})
		:find()
end

M.delete_deck = function(arguments)
	arguments = arguments or {}
	local opts = arguments.opts or {}

	local deck_names = utils.safe_call(ankiconnect.deck_names)
	if not deck_names then
		return
	end
	anki_pickers.pick_one_or_multi("deck", deck_names, opts, function(entry)
		local deck = entry[1]
		utils.safe_call(ankiconnect.delete_decks, { deck })
		notification.info("Deck " .. deck .. " deleted")
	end, function(multi)
		local decks = multi
		utils.safe_call(ankiconnect.delete_decks, decks)
		notification.info(#decks .. " deck(s) deleted")
	end)
end

return M
