local config = require("anki.config")
local curl = require("plenary.curl")

---
--- anki.ankiconnect
---
--- Provides low-level functions to communicate with the AnkiConnect API via HTTP.
--- All functions are asynchronous and use callbacks to avoid blocking Neovim's UI.
--- Wraps all AnkiConnect actions (decks, notes, models, etc.) for use by higher-level modules.
---
--- Callback signature: on_result(result, error)
---   - on success: on_result(result_data, nil)
---   - on failure: on_result(nil, error_message_string)
---
local M = {}

local function anki_connect_invoke_async(options, on_result)
	if type(options) ~= "table" then
		error("[anki.nvim][ankiconnect] Expected a table as argument")
	end
	if type(on_result) ~= "function" then
		error("[anki.nvim][ankiconnect] Expected a function as callback")
	end
	local action = options.action
	local version = options.version or 6
	local params = options.params or vim.empty_dict()

	if not action then
		error("[anki.nvim][ankiconnect] Missing required fields: action")
	end
	if type(version) ~= "number" then
		error("[anki.nvim][ankiconnect] Expected a number as version")
	end
	if type(params) ~= "table" then
		error("[anki.nvim][ankiconnect] Expected a table or nil as params")
	end

	local data = {
		action = action,
		version = version,
		params = params,
	}

	local post_data = vim.json.encode(data, { escape_slash = true })

	curl.post(config.options.url, {
		body = post_data,
		headers = {
			content_type = "application/json",
		},
		timeout = config.options.timeout,
		callback = function(response)
			if response.exit ~= 0 then
				on_result(
					nil,
					[=[Failed to send request, make sure Anki is running and AnkiConnect is installed. Please:
    1. Make sure Anki is running
    2. Verify AnkiConnect addon is installed in Anki
    3. Check that the URL in the config is correct]=]
				)
				return
			end

			local ok, decoded = pcall(vim.json.decode, response.body, { luanil = { objects = false, array = false } })
			if not ok then
				on_result(nil, "[anki.nvim][ankiconnect] Failed to decode JSON response: " .. tostring(decoded))
				return
			end

			if decoded.error ~= nil and decoded.error ~= vim.NIL then
				on_result(nil, vim.inspect(decoded.error))
				return
			end

			on_result(decoded.result, nil)
		end,
	})
end

M.deck_names = function(on_result)
	anki_connect_invoke_async({ action = "deckNames" }, on_result)
end

M.version = function(on_result)
	anki_connect_invoke_async({ action = "version" }, on_result)
end

M.request_permission = function(on_result)
	anki_connect_invoke_async({ action = "requestPermission" }, on_result)
end

---
--- Finds notes in Anki matching the given query string.
---
---@param query string The search query.
---@param on_result function Callback: on_result(note_ids, error)
M.find_notes = function(query, on_result)
	anki_connect_invoke_async({ action = "findNotes", params = { query = query } }, on_result)
end

---
--- Gets detailed information for a list of note IDs.
---
---@param notes table List of note IDs.
---@param on_result function Callback: on_result(notes_info, error)
M.notes_info = function(notes, on_result)
	anki_connect_invoke_async({ action = "notesInfo", params = { notes = notes } }, on_result)
end

M.create_deck = function(deck, on_result)
	anki_connect_invoke_async({ action = "createDeck", params = { deck = deck } }, on_result)
end

M.model_names = function(on_result)
	anki_connect_invoke_async({ action = "modelNames" }, on_result)
end

M.get_tags = function(on_result)
	anki_connect_invoke_async({ action = "getTags" }, on_result)
end

M.model_field_names = function(modelName, on_result)
	anki_connect_invoke_async({ action = "modelFieldNames", params = { modelName = modelName } }, on_result)
end

---
--- Adds a note to Anki via AnkiConnect.
---
---@param deckName string The name of the deck.
---@param modelName string The name of the model.
---@param fields table The note fields.
---@param tags table The note tags.
---@param media table|nil Optional media attachments.
---@param on_result function Callback: on_result(note_id, error)
M.add_note = function(deckName, modelName, fields, tags, media, on_result)
	local note = {
		deckName = deckName,
		modelName = modelName,
		fields = fields,
		options = {
			allowDuplicate = false,
			duplicateScope = "deck",
			duplicateScopeOptions = {
				deckName = nil,
				checkChildren = false,
				checkAllModels = false,
			},
		},
		tags = tags,
	}
	if media then
		if media.picture then
			note.picture = media.picture
		end
		if media.audio then
			note.audio = media.audio
		end
		if media.video then
			note.video = media.video
		end
	end
	anki_connect_invoke_async({
		action = "addNote",
		params = {
			note = note,
		},
	}, on_result)
end

M.can_add_notes_with_error_details = function(deckName, modelName, fields, tags, on_result)
	anki_connect_invoke_async({
		action = "canAddNotesWithErrorDetail",
		params = {
			notes = { {
				deckName = deckName,
				modelName = modelName,
				fields = fields,
				tags = tags,
			} },
		},
	}, on_result)
end

M.update_note = function(id, fields, tags, on_result)
	anki_connect_invoke_async({
		action = "updateNote",
		params = {
			note = {
				id = id,
				fields = fields,
				tags = tags,
			},
		},
	}, on_result)
end

---
--- Deletes notes in Anki by note ID.
---
---@param notes table List of note IDs to delete.
---@param on_result function Callback: on_result(result, error)
M.delete_notes = function(notes, on_result)
	if type(notes) ~= "table" then
		error("[anki.nvim][ankiconnect] Expected a table as argument")
	end
	anki_connect_invoke_async({
		action = "deleteNotes",
		params = {
			notes = notes,
		},
	}, on_result)
end

M.delete_decks = function(decks, on_result)
	if type(decks) ~= "table" then
		error("[anki.nvim][ankiconnect] Expected a table as argument")
	end
	anki_connect_invoke_async({
		action = "deleteDecks",
		params = {
			decks = decks,
			cardsToo = true,
		},
	}, on_result)
end

M.gui_browse = function(query, on_result)
	anki_connect_invoke_async({
		action = "guiBrowse",
		params = {
			query = query,
		},
	}, on_result)
end

M.change_deck = function(cards, deck, on_result)
	anki_connect_invoke_async({ action = "changeDeck", params = { cards = cards, deck = deck } }, on_result)
end

---
--- Gets the list of available Anki profiles.
---
---@param on_result function Callback: on_result(profiles, error)
M.get_profiles = function(on_result)
	anki_connect_invoke_async({ action = "getProfiles" }, on_result)
end

---
--- Gets the name of the currently active Anki profile.
---
---@param on_result function Callback: on_result(profile_name, error)
M.get_active_profile = function(on_result)
	anki_connect_invoke_async({ action = "getActiveProfile" }, on_result)
end

---
--- Loads (switches to) the specified Anki profile.
---
---@param name string The name of the profile to load.
---@param on_result function Callback: on_result(result, error)
M.load_profile = function(name, on_result)
	if type(name) ~= "string" then
		error("[anki.nvim][ankiconnect] Expected a string as profile name")
	end
	anki_connect_invoke_async({ action = "loadProfile", params = { name = name } }, on_result)
end

M.store_media_file = function(filename, opts, on_result)
	opts = opts or vim.empty_dict()
	local params = { filename = filename }
	if opts.data then
		params.data = opts.data
	elseif opts.path then
		params.path = opts.path
	elseif opts.url then
		params.url = opts.url
	end
	if opts.delete_existing ~= nil then
		params.deleteExisting = opts.delete_existing
	end
	anki_connect_invoke_async({ action = "storeMediaFile", params = params }, on_result)
end

M.retrieve_media_file = function(filename, on_result)
	anki_connect_invoke_async({ action = "retrieveMediaFile", params = { filename = filename } }, on_result)
end

M.get_media_files_names = function(pattern, on_result)
	anki_connect_invoke_async({
		action = "getMediaFilesNames",
		params = { pattern = pattern or "*" },
	}, on_result)
end

M.get_media_dir_path = function(on_result)
	anki_connect_invoke_async({ action = "getMediaDirPath" }, on_result)
end

M.delete_media_file = function(filename, on_result)
	anki_connect_invoke_async({ action = "deleteMediaFile", params = { filename = filename } }, on_result)
end

return M
