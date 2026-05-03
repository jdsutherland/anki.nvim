local notification = require("anki.notification")
local utils = require("anki.utils")
local ankiconnect = require("anki.ankiconnect")
local operations = require("anki.ui.operations")
local anki_state = require("anki.state")

local M = {}

--- Prompts the user to create a new deck and refreshes the UI.
function M.create_deck()
	vim.ui.input({ prompt = "Enter deck name:" }, function(deck_name)
		if deck_name and deck_name ~= "" then
			local result = utils.safe_call(ankiconnect.create_deck, deck_name)
			if result == nil then
				notification.error("[anki.nvim][deck_ops] Failed to create deck '" .. deck_name .. "'")
				return
			end
			operations.refresh_all()
			notification.info("[anki.nvim][deck_ops] Deck '" .. deck_name .. "' created")
		end
	end)
end

--- Deletes the currently selected deck after user confirmation.
function M.delete_deck()
	local start_line, end_line = utils.get_visual_line_range()

	local decks = {}
	for i = start_line, end_line do
		local deck = anki_state.ui.decks[i]
		if deck then
			table.insert(decks, deck)
		end
	end

	if #decks == 0 then
		notification.warn("[anki.nvim][deck_ops] No decks selected.")
		return
	end

	vim.ui.input({ prompt = "Are you sure you want to delete " .. #decks .. " deck ? (Y/n)" }, function(input)
		if input == nil then
			return
		end
		if input == "Y" or input == "y" then
			local result = utils.safe_call(ankiconnect.delete_decks, decks)
			if result == nil then
				notification.error("[anki.nvim][deck_ops] Failed to delete deck.")
				return
			end
			operations.refresh_all()
		end
	end)
end

--- Opens the GUI browser for the selected deck in Anki.
function M.gui_deck()
	local deck_name = vim.api.nvim_get_current_line()
	if not deck_name then
		return
	end
	local query = string.format('"deck:%s"', utils.escape_search_query(deck_name))
	utils.safe_call(ankiconnect.gui_browse, query)
end

--- Renames the currently selected deck, moving all cards to the new deck name.
function M.rename_deck()
	local current_deck_name = vim.api.nvim_get_current_line()
	if not current_deck_name or current_deck_name == "" then
		notification.warn("[anki.nvim][deck_ops] No deck selected")
		return
	end

	vim.ui.input({
		prompt = "Enter new deck name:",
		default = current_deck_name,
	}, function(new_deck_name)
		if new_deck_name and new_deck_name ~= "" and new_deck_name ~= current_deck_name then
			local note_ids = utils.safe_call(ankiconnect.find_notes, string.format('"deck:%s"', utils.escape_search_query(current_deck_name)))
			if note_ids == nil then
				notification.warn("[anki.nvim][deck_ops] Failed to find notes in deck '" .. current_deck_name .. "'")
				return
			end

			if note_ids and #note_ids > 0 then
				local notes_info = utils.safe_call(ankiconnect.notes_info, note_ids)
				if notes_info == nil then
					notification.warn("[anki.nvim][deck_ops] Failed to get note information")
					return
				end
				local all_card_ids = {}
				for _, note in ipairs(notes_info) do
					if note.cards then
						for _, card_id in ipairs(note.cards) do
							table.insert(all_card_ids, card_id)
						end
					end
				end

				if #all_card_ids > 0 then
					-- Move all cards to new deck (creates it if needed)
					local change_deck_result = utils.safe_call(ankiconnect.change_deck, all_card_ids, new_deck_name)
					if change_deck_result == nil then
						notification.error("[anki.nvim][deck_ops] Failed to move cards to new deck")
						return
					end
					local delete_deck_result = utils.safe_call(ankiconnect.delete_decks, { current_deck_name })
					if delete_deck_result == nil then
						notification.error("[anki.nvim][deck_ops] Failed to delete old deck")
						return
					end
					operations.refresh_all()
					notification.info(
						"[anki.nvim][deck_ops] Deck '" .. current_deck_name .. "' renamed to '" .. new_deck_name .. "'"
					)
				else
					notification.warn("[anki.nvim][deck_ops] No cards found in deck '" .. current_deck_name .. "'")
				end
			else
				notification.warn("[anki.nvim][deck_ops] No notes found in deck '" .. current_deck_name .. "'")
			end
		elseif new_deck_name == current_deck_name then
			notification.info("[anki.nvim][deck_ops] Deck name unchanged")
		end
	end)
end

return M
