local http_request = require("http.request")
local http_headers = require("http.headers")
local json = require("rapidjson")

local M = {}

local anki_connect_invoke = function(options)
	if type(options) ~= "table" then
		error("Expected a table as argument")
	end
	local action = options.action
	local version = options.version or 6
	local params = options.params or {}

	if not action then
		error("Missing required fields: action")
	end
	if type(version) ~= "number" then
		error("Expected a number as version")
	end
	if type(params) ~= "table" then
		error("Expected a table as params")
	end

	local url = vim.g.anki_url

	local data = {
		action = action,
		version = version,
		params = params,
	}
	local post_data = json.encode(data)

	local headers = http_headers.new()
	headers:upsert(":method", "POST")
	headers:upsert(":authority", "localhost")
	headers:upsert(":scheme", "http")
	headers:upsert(":path", "/")
	headers:upsert("content-type", "application/json")
	headers:upsert("content-length", tostring(#post_data))

	local request = http_request.new_from_uri(url)
	request.headers = headers
	request:set_body(post_data)

	local headers_, stream = request:go(vim.g.anki_timeout)
	if not headers_ then
		vim.notify(vim.inspect(headers_))
		error("Failed to send request")
	end

	local body = stream:get_body_as_string()
	if not body then
		error("Failed to get response body")
	end

	return json.decode(body)
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

M.deck_notes = function(query)
	local find_notes_response = M.find_notes(query)
	if find_notes_response.error ~= json.null then
		return find_notes_response
	end
	return M.notes_info(find_notes_response.result)
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

M.gui_browse = function(query)
	return anki_connect_invoke({
		action = "guiBrowse",
		version = 6,
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
