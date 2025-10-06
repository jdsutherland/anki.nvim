local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local conf = require("telescope.config").values
local notification = require("anki.notification")
local utils = require("anki.utils")

local M = {}

function M.note_entry_maker(entry)
	local sorted_fields = {}
	-- Initialize table
	for i = 0, utils.table_length(entry.fields) do
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

function M.pick_one(prompt, results, opts, on_select, entry_maker)
	pickers
		.new(opts, {
			prompt_title = prompt,
			finder = finders.new_table({
				results = results,
				entry_maker = entry_maker,
			}),
			sorter = conf.generic_sorter(opts),
			attach_mappings = function(prompt_bufnr, map)
				actions.select_default:replace(function()
					actions.close(prompt_bufnr)
					local entry = action_state.get_selected_entry()
					if entry then
						on_select(entry)
					else
						notification.warn("No item selected")
					end
				end)
				return true
			end,
		})
		:find()
end

function M.pick_one_or_multi(prompt, results, opts, on_select_one, on_select_multi, entry_maker)
	pickers
		.new(opts, {
			prompt_title = prompt,
			finder = finders.new_table({
				results = results,
				entry_maker = entry_maker,
			}),
			sorter = conf.generic_sorter(opts),
			attach_mappings = function(prompt_bufnr, map)
				actions.select_default:replace(function()
					actions.close(prompt_bufnr)
					local picker = action_state.get_current_picker(prompt_bufnr)
					local multi = picker:get_multi_selection()
					local entry = action_state.get_selected_entry()
					actions.close(prompt_bufnr)
					if entry then
						on_select_one(entry)
					elseif not vim.tbl_isempty(multi) then
						on_select_multi(multi)
					else
						notification.warn("No item selected")
					end
				end)
				return true
			end,
		})
		:find()
end

return M
