local config = require("anki.config")
local anki_state = require("anki.state")
local classes = require("anki.classes")
local utils = require("anki.utils")
local notification = require("anki.notification")

local M = {}

function M.create_note(deck_name, model_name, field_names, display_mode, id)
	local fields = {}

	for _, name in pairs(field_names) do
		table.insert(
			fields,
			classes.Field:new({
				editor_context = classes.EditorContext:new({
					winid = vim.api.nvim_get_current_win(),
					tabid = vim.api.nvim_get_current_tabpage(),
					bufnr = vim.api.nvim_create_buf(true, true),
				}),
				name = name,
			})
		)
	end

	local note = classes.Note:new({
		fields = fields,
		tags = classes.EditorContext:new({
			winid = vim.api.nvim_get_current_win(),
			tabid = vim.api.nvim_get_current_tabpage(),
			bufnr = vim.api.nvim_create_buf(true, true),
		}),
		deck_name = deck_name,
		model_name = model_name,
		id = id,
		display_mode = display_mode,
	})

	table.insert(anki_state.notes, note)

	return note
end

function M.display_note(note, display)
	anki_state.counter = anki_state.counter + 1
	if display == "custom" and config.options.custom_display ~= nil then
		config.options.custom_display(note)
	else
		if display == "tabpage" then
			vim.cmd("tabnew")
		elseif display == "vsplit" then
			vim.cmd("vsplit")
		elseif display == "split" then
			vim.cmd("split")
		end
		local new_winid = vim.api.nvim_get_current_win()
		local new_tabid = vim.api.nvim_get_current_tabpage()

		note.tags.winid = new_winid
		note.tags.tabid = new_tabid

		local counter = anki_state.counter
		vim.api.nvim_buf_set_name(note.tags.bufnr, "anki://Tags_" .. counter)
		vim.api.nvim_win_set_buf(0, note.tags.bufnr)

		if config.options.after_edit_buffer_hook then
			config.options.after_edit_buffer_hook()
		end

		for i = utils.table_length(note.fields), 1, -1 do
			vim.api.nvim_set_option_value("filetype", "html", { buf = note.fields[i].editor_context.bufnr })
			vim.api.nvim_buf_set_name(
				note.fields[i].editor_context.bufnr,
				"anki://" .. note.fields[i].name .. "_" .. counter
			)
			vim.api.nvim_win_set_buf(0, note.fields[i].editor_context.bufnr)

			note.fields[i].editor_context.winid = new_winid
			note.fields[i].editor_context.tabid = new_tabid

			if config.options.after_edit_buffer_hook then
				config.options.after_edit_buffer_hook()
			end
		end
	end
end

function M.search_for_note(bufnr)
	for index, note in ipairs(anki_state.notes) do
		if note.tags.bufnr == bufnr then
			return index
		end
		for _, field in ipairs(note.fields) do
			if field.editor_context.bufnr == bufnr then
				return index
			end
		end
	end
end

function M.delete_note_buffers(note)
	if config.options.custom_delete then
		config.options.custom_delete(note)
	else
		-- Close tags buffer
		vim.api.nvim_buf_delete(note.tags.bufnr, { force = true })

		-- Close fields buffers
		for _, field in pairs(note.fields) do
			vim.api.nvim_buf_delete(field.editor_context.bufnr, { force = true })
		end
	end
end

function M.kill_note(bufnr)
	local found = M.search_for_note(bufnr)
	if not found then
		notification.warn("No Anki note buffer found")
		return
	end

	local note_to_kill = anki_state.notes[found]

	M.delete_note_buffers(note_to_kill)

	table.remove(anki_state.notes, found)
	notification.info("Note buffers killed")
end

function M.kill_all()
	local notes_to_clean = vim.deepcopy(anki_state.notes)
	if #notes_to_clean == 0 then
		notification.info("No active Anki notes to clean up.")
		return
	end

	for _, note in ipairs(notes_to_clean) do
		M.delete_note_buffers(note)
	end

	-- Clear the state table
	anki_state.notes = {}
	notification.info("Cleaned up " .. #notes_to_clean .. " Anki note(s).")
end

return M
