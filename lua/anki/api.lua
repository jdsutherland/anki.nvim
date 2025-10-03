local json = require("rapidjson")
local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local conf = require("telescope.config").values
local ankiconnect = require("anki.ankiconnect")
local anki_state = require("anki.state")
local classes = require("anki.classes")

local M = {}

function string.split(inputstr, sep)
	if sep == nil then
		sep = "%s" -- default separator is whitespace
	end
	local t = {}
	for str in string.gmatch(inputstr, "([^" .. sep .. "]+)") do
		table.insert(t, str)
	end
	return t
end

local function safe_call(fn, ...)
	local response = fn(...)
	if response.error ~= json.null then
		vim.notify(vim.inspect(response.error), vim.log.levels.ERROR)
		return nil
	end
	return response.result
end

M.table_length = function(tbl)
	local length = 0
	for key, value in pairs(tbl) do
		length = length + 1
	end
	return length
end

M.search_for_note = function(bufnr)
	for index, note in ipairs(anki_state.notes) do
		if note.tags.bufnr == bufnr then
			return index
		end
		for _, field in ipairs(note.fields) do
			if field.bufnr == bufnr then
				return index
			end
		end
	end
end

M.delete_note_buffers = function(note)
	if vim.g.anki_custom_delete then
		vim.g.anki_custom_delete(note)
	else
		-- Close tags buffer
		vim.api.nvim_buf_delete(note.tags.bufnr, { force = true })

		-- Close fields buffers
		for _, field in pairs(note.fields) do
			vim.api.nvim_buf_delete(field.bufnr, { force = true })
		end
	end
end

M.display_note = function(note, display)
	anki_state.counter = anki_state.counter + 1
	if display == "custom" then
		vim.g.anki_custom_display(note)
	else
		local counter = anki_state.counter
		vim.api.nvim_buf_set_name(note.tags.bufnr, "anki://Tags_" .. counter)

		if display == "tabpage" then
			vim.api.nvim_command("tabnew " .. "anki://Tags_" .. counter)
		elseif display == "vsplit" then
			vim.api.nvim_command("vsplit " .. "anki://Tags_" .. counter)
		elseif display == "split" then
			vim.api.nvim_command("split " .. "anki://Tags_" .. counter)
		end

		vim.api.nvim_command("edit " .. "anki://Tags_" .. counter)
		if vim.g.anki_after_edit_buffer_hook then
			vim.g.anki_after_edit_buffer_hook()
		end

		for i = M.table_length(note.fields), 1, -1 do
			vim.api.nvim_set_option_value("filetype", "html", { buf = note.fields[i].bufnr })
			vim.api.nvim_buf_set_name(note.fields[i].bufnr, "anki://" .. note.fields[i].name .. "_" .. counter)
			vim.api.nvim_command("edit " .. "anki://" .. note.fields[i].name .. "_" .. counter)
			if vim.g.anki_after_edit_buffer_hook then
				vim.g.anki_after_edit_buffer_hook()
			end
		end
	end
end

M.add_note = function(arguments)
	arguments = arguments or {}
	local opts = arguments.opts or {}
	local display = arguments.display or nil

	local result_deck_names = safe_call(ankiconnect.deck_names)
	if not result_deck_names then
		return
	end
	local result_model_names = safe_call(ankiconnect.model_names)
	if not result_model_names then
		return
	end

	pickers
		.new(opts, {
			prompt_title = "decks",
			finder = finders.new_table({
				results = result_deck_names,
			}),
			sorter = conf.generic_sorter(opts),
			attach_mappings = function(prompt_bufnr, map)
				actions.select_default:replace(function()
					actions.close(prompt_bufnr)

					local deck_selection = action_state.get_selected_entry()

					pickers
						.new(opts, {
							prompt_title = "models",
							finder = finders.new_table({
								results = result_model_names,
							}),
							sorter = conf.generic_sorter(opts),
							attach_mappings = function(prompt_bufnr, map)
								actions.select_default:replace(function()
									actions.close(prompt_bufnr)

									local model_selection = action_state.get_selected_entry()

									local result_field_names =
										safe_call(ankiconnect.model_field_names, model_selection[1])
									if not result_field_names then
										return
									end

									local note = classes.Note:new({
										fields = {},
										tags = {
											bufnr = nil,
										},
										deck_name = deck_selection[1],
										model_name = model_selection[1],
									})

									-- Create the tags buffer
									note.tags.bufnr = vim.api.nvim_create_buf(true, true)

									-- Create buffers for the note fields
									for _, name in ipairs(result_field_names) do
										table.insert(
											note.fields,
											classes.Field:new({
												bufnr = vim.api.nvim_create_buf(true, true),
												name = name,
											})
										)
									end

									table.insert(anki_state.notes, note)

									M.display_note(note, display)
								end)
								return true
							end,
						})
						:find()
				end)
				return true
			end,
		})
		:find()
end

M.add_note_to_quick_deck = function(arguments)
	arguments = arguments or {}
	local opts = arguments.opts or {}
	local display = arguments.display or nil

	if not anki_state.quickdeck then
		return
	end

	local result_model_names = safe_call(ankiconnect.model_names)
	if not result_model_names then
		return
	end

	pickers
		.new(opts, {
			prompt_title = "models",
			finder = finders.new_table({
				results = result_model_names,
			}),
			sorter = conf.generic_sorter(opts),
			attach_mappings = function(prompt_bufnr, map)
				actions.select_default:replace(function()
					actions.close(prompt_bufnr)

					local model_selection = action_state.get_selected_entry()

					local result_field_names = safe_call(ankiconnect.model_field_names, model_selection[1])
					if not result_field_names then
						return
					end

					local note = classes.Note:new({
						fields = {},
						tags = {
							bufnr = nil,
						},
						deck_name = anki_state.quickdeck,
						model_name = model_selection[1],
					})

					-- Create the tags buffer
					note.tags.bufnr = vim.api.nvim_create_buf(true, true)

					-- Create buffers for the note fields
					for _, name in ipairs(result_field_names) do
						table.insert(
							note.fields,
							classes.Field:new({
								bufnr = vim.api.nvim_create_buf(true, true),
								name = name,
							})
						)
					end

					table.insert(anki_state.notes, note)

					M.display_note(note, display)
				end)
				return true
			end,
		})
		:find()
end

M.select_state_quickdeck = function(opts)
	opts = opts or {}
	local result_deck_names = safe_call(ankiconnect.deck_names)
	if not result_deck_names then
		return
	end
	pickers
		.new(opts, {
			prompt_title = "decks",
			finder = finders.new_table({
				results = result_deck_names,
			}),
			sorter = conf.generic_sorter(opts),
			attach_mappings = function(prompt_bufnr, map)
				actions.select_default:replace(function()
					actions.close(prompt_bufnr)
					local deck_selection = action_state.get_selected_entry()
					anki_state.quickdeck = deck_selection[1]
				end)
				return true
			end,
		})
		:find()
end

M.note_entry_maker = function(entry)
	local sorted_fields = {}
	-- Initialize table
	for i = 0, M.table_length(entry.fields) do
		sorted_fields[(i + 1)] = nil
	end

	-- NOTE: field.order starts at 0
	for key, field in pairs(entry.fields) do
		table.insert(sorted_fields, (field.order + 1), {
			value = field.value,
			name = key,
		})
	end

	-- https://github.com/nvim-telescope/telescope.nvim/issues/3163#issuecomment-2167678288
	local display, ordinal = "", ""
	for _, field in pairs(sorted_fields) do
		display = display .. " [" .. field.name:gsub("\n", "") .. "]> " .. field.value:gsub("\n", "")
		ordinal = ordinal .. " [" .. field.name:gsub("\n", "") .. "]> " .. field.value:gsub("\n", "")
	end

	return {
		value = entry,
		display = display,
		ordinal = ordinal,
	}
end

M.edit_note_from_quick_deck = function(arguments)
	arguments = arguments or {}
	local opts = arguments.opts or {}
	local display = arguments.display or nil

	if not anki_state.quickdeck then
		return
	end
	local query = string.format('"deck:%s"', anki_state.quickdeck)
	local result_notes_ids = safe_call(ankiconnect.find_notes, query)
	if not result_notes_ids then
		return
	end
	local result_notes_info = safe_call(ankiconnect.notes_info, result_notes_ids)
	if not result_notes_info then
		return
	end

	if next(result_notes_info) == nil then
		vim.notify("Deck [" .. anki_state.quickdeck .. "] is empty", vim.log.levels.ERROR)
		return
	end

	pickers
		.new(opts, {
			prompt_title = "notes",
			finder = finders.new_table({
				results = result_notes_info,
				entry_maker = M.note_entry_maker,
			}),
			sorter = conf.generic_sorter(opts),
			attach_mappings = function(prompt_bufnr, map)
				actions.select_default:replace(function()
					actions.close(prompt_bufnr)
					local note_selection = action_state.get_selected_entry()
					if not note_selection then
						vim.notify("Empty selection", vim.log.levels.ERROR)
						return false
					end

					local note = classes.Note:new({
						fields = {},
						tags = {
							bufnr = nil,
						},
						id = note_selection.value.noteId,
						model_name = note_selection.value.modelName,
						deck_name = anki_state.quickdeck,
					})

					local sorted_fields = {}
					-- Initialize table
					for i = 0, M.table_length(note_selection.value.fields) do
						sorted_fields[(i + 1)] = nil
					end

					for key, field in pairs(note_selection.value.fields) do
						table.insert(sorted_fields, (field.order + 1), {
							value = field.value,
							name = key,
						})
					end

					-- Create the tag buffer
					note.tags.bufnr = vim.api.nvim_create_buf(true, true)

					-- Create the fields buffers
					for _, field in pairs(sorted_fields) do
						table.insert(
							note.fields,
							classes.Field:new({
								bufnr = vim.api.nvim_create_buf(true, true),
								name = field.name,
							})
						)
					end

					-- Set the content of the tags buffers
					vim.api.nvim_buf_set_lines(note.tags.bufnr, 0, -1, false, note_selection.value.tags)

					-- Set the content of the fields buffers
					for i, v in pairs(sorted_fields) do
						vim.api.nvim_buf_set_lines(note.fields[i].bufnr, 0, -1, false, string.split(v.value, "\n"))
					end

					table.insert(anki_state.notes, note)

					M.display_note(note, display)
				end)
				return true
			end,
		})
		:find()
end

M.kill_note = function(bufnr)
	local found = M.search_for_note(bufnr)
	if not found then
		vim.notify("Note not Found in kill note", vim.log.levels.ERROR)
		return
	end

	local note_to_kill = anki_state.notes[found]

	M.delete_note_buffers(note_to_kill)

	table.remove(anki_state.notes, found)

	vim.notify("Note killed")
end

M.send_note = function(bufnr, kill)
	kill = kill or nil
	local found = M.search_for_note(bufnr)
	if not found then
		vim.notify("Note not Found in send note", vim.log.levels.ERROR)
		return
	end

	local note_to_send = anki_state.notes[found]

	local fields = {}

	for _, field in pairs(note_to_send.fields) do
		fields[field.name] = vim.fn.join(vim.api.nvim_buf_get_lines(field.bufnr, 0, -1, false), " ")
	end

	local tags = vim.api.nvim_buf_get_lines(note_to_send.tags.bufnr, 0, -1, false)

	local msg_status = (note_to_send.id == nil) or false and true

	-- Make sure the note stil exists in anki
	if note_to_send.id then
		local query = string.format("nid:%s", note_to_send.id)
		local result_notes = safe_call(ankiconnect.find_notes, query)
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
	local result_can_add_note = safe_call(
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
		vim.notify(vim.inspect("The note already exists but it's id is unknwon by anki.nvim"), vim.log.levels.ERROR)
		return
	end

	if note_to_send.id == nil and can_add_note then
		local result_note_id =
			safe_call(ankiconnect.add_note, note_to_send.deck_name, note_to_send.model_name, fields, tags)
		if not result_note_id then
			return
		end

		note_to_send.id = result_note_id

		if vim.g.anki_gui_browse_enabled then
			local query = string.format('"deck:%s" nid:%s', note_to_send.deck_name, note_to_send.id)
			local _ = safe_call(ankiconnect.gui_browse, query)
		end
	else
		-- -- https://github.com/FooSoft/anki-connect/issues/82#issuecomment-1221895385
		if vim.g.anki_gui_browse_enabled then
			local query = "nid:1"
			local _ = safe_call(ankiconnect.gui_browse, query)
		end

		local _ = safe_call(ankiconnect.update_note, note_to_send.id, fields, tags)

		if vim.g.anki_gui_browse_enabled then
			local query = string.format('"deck:%s" nid:%s', note_to_send.deck_name, note_to_send.id)
			local _ = safe_call(ankiconnect.gui_browse, query)
		end
	end

	if kill then
		M.delete_note_buffers(note_to_send)
		table.remove(anki_state.notes, found)
	end

	if msg_status then
		vim.notify("Anki note added.")
	else
		vim.notify("Anki note updated.")
	end
end

M.edit_note = function(opts)
	opts = opts or {}

	local result_deck_names = safe_call(ankiconnect.deck_names)
	if not result_deck_names then
		return
	end

	pickers
		.new(opts, {
			prompt_title = "decks",
			finder = finders.new_table({
				results = result_deck_names,
			}),
			sorter = conf.generic_sorter(opts),
			attach_mappings = function(prompt_bufnr, map)
				actions.select_default:replace(function()
					actions.close(prompt_bufnr)
					local deck_selection = action_state.get_selected_entry()

					local query = string.format('"deck:%s"', deck_selection[1])
					local result_notes_info = safe_call(ankiconnect.deck_notes, query)
					if not result_notes_info then
						return
					end
					if next(result_notes_info) == nil then
						vim.notify("Deck [" .. deck_selection[1] .. "] is empty", vim.log.levels.ERROR)
						return
					end

					pickers
						.new(opts, {
							prompt_title = "notes",
							finder = finders.new_table({
								results = result_notes_info,
								entry_maker = M.note_entry_maker,
							}),
							sorter = conf.generic_sorter(opts),
							attach_mappings = function(prompt_bufnr, map)
								actions.select_default:replace(function()
									actions.close(prompt_bufnr)

									local note_selection = action_state.get_selected_entry()
									if not note_selection then
										vim.notify("Empty selection", vim.log.levels.ERROR)
										return false
									end

									-- Create the note
									--TODO: Initilize the buffers in a constructor ?

									local note = classes.Note:new({
										fields = {},
										tags = {
											bufnr = nil,
										},
										id = note_selection.value.noteId,
										model_name = note_selection.value.modelName,
										deck_name = deck_selection[1],
									})

									local sorted_fields = {}

									-- Initialize table
									for i = 0, M.table_length(note_selection.value.fields) do
										sorted_fields[(i + 1)] = nil
									end

									for key, field in pairs(note_selection.value.fields) do
										table.insert(sorted_fields, (field.order + 1), {
											value = field.value,
											name = key,
										})
									end

									-- Create the fields buffers
									for _, field in pairs(sorted_fields) do
										table.insert(
											note.fields,
											classes.Field:new({
												bufnr = vim.api.nvim_create_buf(true, true),
												name = field.name,
											})
										)
									end

									-- Create the tag buffer
									note.tags.bufnr = vim.api.nvim_create_buf(true, true)

									-- Set the content of the tags buffers
									vim.api.nvim_buf_set_lines(note.tags.bufnr, 0, -1, false, note_selection.value.tags)

									-- Set the content of the fields buffers
									for i, _ in ipairs(sorted_fields) do
										vim.api.nvim_buf_set_lines(
											note.fields[i].bufnr,
											0,
											-1,
											false,
											string.split(sorted_fields[i].value, "\n")
										)
									end

									table.insert(anki_state.notes, note)

									M.display_note(note)
								end)
								return true
							end,
						})
						:find()
				end)
				return true
			end,
		})
		:find()
end

M.pull_note = function(bufnr)
	local found = M.search_for_note(bufnr)
	if not found then
		vim.notify("Note not Found in pull note", vim.log.levels.ERROR)
		return
	end
	local note_to_pull = anki_state.notes[found]
	if not note_to_pull.id then
		vim.notify("Note doesn't have an id", vim.log.levels.ERROR)
		return
	end

	-- get the note infos
	local result_notes_info = safe_call(ankiconnect.notes_info, { note_to_pull.id })
	if not result_notes_info then
		return
	end
	local first_note = result_notes_info[1]

	for key, field in pairs(first_note.fields) do
		local field_found_in_note = note_to_pull:find_field_by_name(key)
		if field_found_in_note then
			vim.api.nvim_buf_set_lines(
				note_to_pull.fields[field_found_in_note].bufnr,
				0,
				-1,
				false,
				string.split(field.value)
			)
		end
	end
	vim.notify("Anki note pulled.")
end

M.delete_note = function(bufnr)
	local found = M.search_for_note(bufnr)
	if not found then
		vim.notify("Note not found", vim.log.levels.ERROR)
		return
	end
	local note_to_delete = anki_state.notes[found]
	if note_to_delete.id == nil then
		vim.notify("Can Not Delete The Note Because It Wasn't Yet Sent To Anki")
		return
	end

	local _ = safe_call(ankiconnect.delete_notes, { note_to_delete.id })

	if vim.g.anki_gui_browse_enabled then
		local query = string.format('"deck:%s"', note_to_delete.deck_name)
		local _ = safe_call(ankiconnect.gui_browse, query)
	end

	note_to_delete.id = nil
	vim.notify("Anki Note Deleted")
end

M.pick_delete_notes = function(opts)
	local result_deck_names = safe_call(ankiconnect.deck_names)
	if not result_deck_names then
		return
	end
	pickers
		.new(opts, {
			prompt_title = "decks",
			finder = finders.new_table({
				results = result_deck_names,
			}),
			sorter = conf.generic_sorter(opts),
			attach_mappings = function(prompt_bufnr, map)
				actions.select_default:replace(function()
					actions.close(prompt_bufnr)

					local deck_selection = action_state.get_selected_entry()

					local query = string.format('"deck:%s"', deck_selection[1])
					local result_deck_notes = safe_call(ankiconnect.deck_notes, query)
					if not result_deck_notes then
						return
					end
					if next(result_deck_notes) == nil then
						vim.notify("Deck [" .. deck_selection[1] .. "] is empty", vim.log.levels.ERROR)
						return
					end

					pickers
						.new(opts, {
							prompt_title = "notes",
							finder = finders.new_table({
								results = result_deck_notes,
								entry_maker = M.note_entry_maker,
							}),
							sorter = conf.generic_sorter(opts),
							attach_mappings = function(prompt_bufnr, map)
								actions.select_default:replace(function()
									local picker = action_state.get_current_picker(prompt_bufnr)
									local multi = picker:get_multi_selection()

									actions.close(prompt_bufnr)
									if vim.tbl_isempty(multi) then
										local note_selection = action_state.get_selected_entry()
										if not note_selection then
											vim.notify("Empty selection", vim.log.levels.ERROR)
											return false
										end
										local note_id_to_delete = note_selection.value.noteId

										local _ = safe_call(ankiconnect.delete_notes, { note_id_to_delete })
										vim.notify("Anki Note Deleted")
									else
										for _, note in ipairs(multi) do
											local note_id_to_delete = note.value.noteId
											local _ = safe_call(ankiconnect.delete_notes, { note_id_to_delete })
											vim.notify("Anki Note " .. note_id_to_delete .. " Deleted")
										end
									end

									if vim.g.anki_gui_browse_enabled then
										local query = string.format('"deck:%s"', deck_selection[1])
										local _ = safe_call(ankiconnect.gui_browse, query)
										vim.notify("Anki Gui Browsed to deck " .. deck_selection[1])
									end
									return true
								end)
								return true
							end,
						})
						:find()
				end)
				return true
			end,
		})
		:find()
end

M.pick_notes_to_delete_from_quick_deck = function(opts)
	if not anki_state.quickdeck then
		return
	end
	local query = string.format('"deck:%s"', anki_state.quickdeck)
	local result_deck_notes = safe_call(ankiconnect.deck_notes, query)
	if not result_deck_notes then
		return
	end

	if next(result_deck_notes) == nil then
		vim.notify("Deck [" .. anki_state.quickdeck .. "] is empty", vim.log.levels.ERROR)
		return
	end

	pickers
		.new(opts, {
			prompt_title = "notes",
			finder = finders.new_table({
				results = result_deck_notes,
				entry_maker = M.note_entry_maker,
			}),
			sorter = conf.generic_sorter(opts),
			attach_mappings = function(prompt_bufnr, map)
				actions.select_default:replace(function()
					local picker = action_state.get_current_picker(prompt_bufnr)
					local multi = picker:get_multi_selection()

					actions.close(prompt_bufnr)

					if vim.tbl_isempty(multi) then
						local note_selection = action_state.get_selected_entry()
						if not note_selection then
							vim.notify("Empty selection", vim.log.levels.ERROR)
							return false
						end
						local note_id_to_delete = note_selection.value.noteId

						local _ = safe_call(ankiconnect.delete_notes, { note_id_to_delete })
						vim.notify("Anki Note Deleted")
					else
						for _, note in ipairs(multi) do
							local note_id_to_delete = note.value.noteId
							local _ = safe_call(ankiconnect.delete_notes, { note_id_to_delete })
							vim.notify("Anki Note " .. note_id_to_delete .. " Deleted")
						end
					end

					if vim.g.anki_gui_browse_enabled then
						local query = string.format('"deck:%s"', anki_state.quickdeck)
						local _ = safe_call(ankiconnect.gui_browse, query)
						vim.notify("Anki Gui Browsed to deck " .. anki_state.quickdeck)
					end

					return true
				end)
				return true
			end,
		})
		:find()
end

M.infos = function()
	local infos_bufnr = vim.api.nvim_create_buf(false, true)
	-- Add the buffer mappings
	vim.api.nvim_buf_set_keymap(infos_bufnr, "n", "q", "<Cmd>bd!<CR>", { noremap = true, silent = true })

	local found = M.search_for_note(vim.api.nvim_get_current_buf())
	local current_note = nil
	if found then
		current_note = anki_state.notes[found]
	end

	-- Add the text content
	local content = {
		"--- Configuration",
		"anki_url\t\t\t\t\t\t\t\t\t\t" .. vim.g.anki_url,
		"anki_timeout\t\t\t\t\t\t\t\t" .. vim.g.anki_timeout,
		"anki_prefix\t\t\t\t\t\t\t\t\t" .. vim.g.anki_prefix,
		"anki_default_mappings\t\t\t\t" .. tostring(vim.g.anki_default_mappings),
		"anki_quickdeck\t\t\t\t\t\t\t" .. vim.g.anki_quickdeck,
		"anki_gui_browse_enabled \t\t" .. tostring(vim.g.anki_gui_browse_enabled),
		"anki_custom_display\t\t\t\t\t" .. (vim.g.anki_custom_display and tostring(true) or tostring(false)),
		"anki_custom_delete\t\t\t\t\t" .. (vim.g.anki_custom_delete and tostring(true) or tostring(false)),
		"anki_after_edit_buffer_hook\t" .. (vim.g.anki_after_edit_buffer_hook and tostring(true) or tostring(false)),
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
	local _ = safe_call(ankiconnect.gui_browse, query)
	vim.notify("Anki Gui Browsed to " .. deck .. " deck")
end

M.gui_deck_current = function(bufnr)
	local found = M.search_for_note(bufnr)
	if not found then
		vim.notify("Note not Found in gui deck urrent", vim.log.levels.ERROR)
		return
	end
	local current_note = anki_state.notes[found]

	local query = string.format('"deck:%s"', current_note.deck_name)
	local _ = safe_call(ankiconnect.gui_browse, query)
	vim.notify("Anki Gui Browsed to " .. current_note.deck_name .. " deck")
end

M.gui_note = function(bufnr)
	local found = M.search_for_note(bufnr)
	if not found then
		vim.notify("Note not Found in gui deck urrent", vim.log.levels.ERROR)
		return
	end

	local current_note = anki_state.notes[found]

	if not current_note.id then
		vim.notify("Note id nil, can't browse to note in the gui", vim.log.levels.WARN)
		return
	end

	local query = string.format("nid:%s", current_note.id)
	local _ = safe_call(ankiconnect.gui_browse, query)
	vim.notify("Anki Gui Browsed to " .. current_note.id .. " note id")
end

M.add_deck = function(arguments)
	arguments = arguments or {}
	local opts = arguments.opts or {}

	local deck_names = safe_call(ankiconnect.deck_names)
	if not deck_names then
		return
	end

	pickers
		.new(opts, {
			prompt_title = "Create or Select Deck",
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
						vim.notify("No deck name provided", vim.log.levels.WARN)
						return
					end
					local _ = safe_call(ankiconnect.create_deck, deck_to_create)
					vim.notify("Deck '" .. deck_to_create .. "' created (or already existed).")
				end)
				return true
			end,
			enable_prompt = true, -- allows free typing
		})
		:find()
end

return M
