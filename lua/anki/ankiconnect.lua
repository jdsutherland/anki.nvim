local config = require("anki.config")
local curl = require("plenary.curl")

---
--- anki.ankiconnect
---
--- Provides low-level functions to communicate with the AnkiConnect API via HTTP.
--- Wraps all AnkiConnect actions (decks, notes, models, etc.) for use by higher-level modules.
---
local M = {}

local anki_connect_invoke = function(options)
	if type(options) ~= "table" then
		error("[anki.nvim][ankiconnect] Expected a table as argument")
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

	local response = curl.post(config.options.url, {
		body = post_data,
		headers = {
			content_type = "application/json",
		},
		timeout = config.options.timeout,
	})

	if response.exit ~= 0 then
		error([[Failed to send request, make sure Anki is running and AnkiConnect is installed. Please:
    1. Make sure Anki is running
    2. Verify AnkiConnect addon is installed in Anki
    3. Check that the URL in the config is correct]])
	end

	return vim.json.decode(response.body, { luanil = { objects = false, array = false } })
end

M.deck_names = function()
	return anki_connect_invoke({ action = "deckNames" })
end

M.version = function()
	return anki_connect_invoke({ action = "version" })
end

M.request_permission = function()
	return anki_connect_invoke({ action = "requestPermission" })
end

---
--- Finds notes in Anki matching the given query string.
---
--- @param query string The search query.
--- @return table|nil List of note IDs, or nil on error.
--- @error Throws if query is not a string or AnkiConnect fails.
M.find_notes = function(query)
	return anki_connect_invoke({ action = "findNotes", params = { query = query } })
end

---
--- Gets detailed information for a list of note IDs.
---
--- @param notes table List of note IDs.
--- @return table|nil List of note info tables, or nil on error.
--- @error Throws if notes is not a table or AnkiConnect fails.
M.notes_info = function(notes)
	return anki_connect_invoke({ action = "notesInfo", params = { notes = notes } })
end

M.create_deck = function(deck)
	return anki_connect_invoke({ action = "createDeck", params = { deck = deck } })
end

M.model_names = function()
	return anki_connect_invoke({ action = "modelNames" })
end

M.get_tags = function()
	return anki_connect_invoke({ action = "getTags" })
end

M.model_field_names = function(modelName)
	return anki_connect_invoke({ action = "modelFieldNames", params = { modelName = modelName } })
end

---
--- Adds a note to Anki via AnkiConnect.
---
--- @param deckName string The name of the deck.
--- @param modelName string The name of the model.
--- @param fields table The note fields.
--- @param tags table The note tags.
--- @return table|nil The result from AnkiConnect, or nil on error.
--- @error Throws if arguments are invalid or AnkiConnect fails.
M.add_note = function(deckName, modelName, fields, tags, media)
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
	return anki_connect_invoke({
		action = "addNote",
		params = {
			note = note,
		},
	})
end

M.can_add_notes_with_error_details = function(deckName, modelName, fields, tags)
	return anki_connect_invoke({
		action = "canAddNotesWithErrorDetail",
		params = {
			notes = { {
				deckName = deckName,
				modelName = modelName,
				fields = fields,
				tags = tags,
			} },
		},
	})
end

M.update_note = function(id, fields, tags)
	return anki_connect_invoke({
		action = "updateNote",
		params = {
			note = {
				id = id,
				fields = fields,
				tags = tags,
			},
		},
	})
end

---
--- Deletes notes in Anki by note ID.
---
--- @param notes table List of note IDs to delete.
--- @return table|nil The result from AnkiConnect, or nil on error.
--- @error Throws if notes is not a table or AnkiConnect fails.
M.delete_notes = function(notes)
	if type(notes) ~= "table" then
		error("[anki.nvim][ankiconnect] Expected a table as argument")
	end
	return anki_connect_invoke({
		action = "deleteNotes",
		params = {
			notes = notes,
		},
	})
end

M.delete_decks = function(decks)
	if type(decks) ~= "table" then
		error("[anki.nvim][ankiconnect] Expected a table as argument")
	end
	return anki_connect_invoke({
		action = "deleteDecks",
		params = {
			decks = decks,
			cardsToo = true,
		},
	})
end

M.gui_browse = function(query)
	return anki_connect_invoke({
		action = "guiBrowse",
		params = {
			query = query,
			-- reorderCards = {
			-- 	order = "descending",
			-- 	columnId = "noteCrt",
			-- },
		},
	})
end

M.change_deck = function(cards, deck)
	return anki_connect_invoke({ action = "changeDeck", params = { cards = cards, deck = deck } })
end

---
--- Gets the list of available Anki profiles.
---
--- @return table|nil List of profile names, or nil on error.
--- @error Throws if AnkiConnect fails.
M.get_profiles = function()
	return anki_connect_invoke({ action = "getProfiles" })
end

---
--- Gets the name of the currently active Anki profile.
---
--- @return string|nil The active profile name, or nil on error.
--- @error Throws if AnkiConnect fails.
M.get_active_profile = function()
	return anki_connect_invoke({ action = "getActiveProfile" })
end

---
--- Loads (switches to) the specified Anki profile.
---
--- @param name string The name of the profile to load.
--- @return boolean|nil True if successful, or nil on error.
--- @error Throws if name is not a string or AnkiConnect fails.
M.load_profile = function(name)
	if type(name) ~= "string" then
		error("[anki.nvim][ankiconnect] Expected a string as profile name")
	end
	return anki_connect_invoke({ action = "loadProfile", params = { name = name } })
end

M.store_media_file = function(filename, opts)
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
	return anki_connect_invoke({ action = "storeMediaFile", params = params })
end

M.retrieve_media_file = function(filename)
	return anki_connect_invoke({ action = "retrieveMediaFile", params = { filename = filename } })
end

M.get_media_files_names = function(pattern)
	return anki_connect_invoke({
		action = "getMediaFilesNames",
		params = { pattern = pattern or "*" },
	})
end

M.get_media_dir_path = function()
	return anki_connect_invoke({ action = "getMediaDirPath" })
end

M.delete_media_file = function(filename)
	return anki_connect_invoke({ action = "deleteMediaFile", params = { filename = filename } })
end

return M
