local config = require("anki.config")
local http_request = require("http.request")
local http_headers = require("http.headers")

local M = {}

local anki_connect_invoke = function(options)
	if type(options) ~= "table" then
		error("Expected a table as argument")
	end
	local action = options.action
	local version = options.version or 6
	local params = options.params or vim.empty_dict()

	if not action then
		error("Missing required fields: action")
	end
	if type(version) ~= "number" then
		error("Expected a number as version")
	end
	if type(params) ~= "table" then
		error("Expected a table or nil as params")
	end

	local data = {
		action = action,
		version = version,
		params = params,
	}

	local post_data = vim.json.encode(data, { escape_slash = true })

	local headers = http_headers.new()
	headers:upsert(":method", "POST")
	headers:upsert(":authority", "localhost")
	headers:upsert(":scheme", "http")
	headers:upsert(":path", "/")
	headers:upsert("content-type", "application/json")
	headers:upsert("content-length", tostring(#post_data))

	local request = http_request.new_from_uri(config.options.url)
	request.headers = headers
	request:set_body(post_data)

	local headers_, stream = request:go(config.options.timeout)
	if not headers_ then
		vim.notify(vim.inspect(headers_))
		error("Failed to send request, make sure Anki is running and AnkiConnect is installed")
	end

	local body = stream:get_body_as_string()
	if not body then
		error("Failed to get response body")
	end

	return vim.json.decode(body, { luanil = { objects = false, array = false } })
end

M.deck_names = function()
	return anki_connect_invoke({ action = "deckNames" })
end

M.find_notes = function(query)
	return anki_connect_invoke({ action = "findNotes", params = { query = query } })
end

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

M.add_note = function(deckName, modelName, fields, tags)
	return anki_connect_invoke({
		action = "addNote",
		params = {
			note = {
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
			},
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

M.delete_notes = function(notes)
	if type(notes) ~= "table" then
		error("Expected a table as argument")
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
		error("Expected a table as argument")
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

return M
