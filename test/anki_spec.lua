-- Add the plugin's parent directory to the runtimepath
vim.opt.runtimepath:append("/home/user/.config/nvim/lua/myplugins")

local deckname = "TestDeck"

describe("anki", function()
	it("can be required", function()
		require("anki")
	end)

	it("deck_names returns a table", function()
		local decks = require("anki.ankiconnect").deck_names()
		assert(type(decks) == "table", "decks is not a table")
	end)

	it("create_deck result returns a number", function()
		local response = require("anki.ankiconnect").create_deck(deckname)
		assert(type(response.result) == "number", "deck_id is not a number")
	end)

	it("find_notes returns a table of numbers", function()
		-- local notes = require("anki.ankiconnect").find_notes('"deck:' .. deckname .. '"')
		-- assert(type(notes) == "table", "notes is not a table")
		-- for _, note in ipairs(notes) do
		-- 	assert(type(note) == "number", "note is not a number")
		-- end
	end)

	it("notes_info returns a table of table", function()
		local notes = require("anki.ankiconnect").find_notes(deckname)
		local notes_info = require("anki.ankiconnect").notes_info(notes)
		assert(type(notes_info) == "table", "notes_info is not a table")
		for _, note_info in ipairs(notes_info) do
			assert(type(note_info) == "table", "note_info is not a table")
		end
	end)

	it("deck_notes returns a table of table", function()
		local notes = require("anki.ankiconnect").deck_notes("deck:" .. deckname)
		assert(type(notes) == "table", "notes is not a table")
		for _, note in ipairs(notes) do
			assert(type(note) == "table", "note is not a table")
		end
	end)

	it("model_names returns a table of strings", function()
		-- local models = require("anki.ankiconnect").model_names()
		-- assert(type(models) == "table", "models is not a table")
		-- for _, model in ipairs(models) do
		-- 	assert(type(model) == "string", "model is not a string")
		-- end
	end)

	it("get_tags returns a table of string", function()
		-- local tags = require("anki.ankiconnect").get_tags()
		-- assert(type(tags) == "table", "tags is not a table")
		-- for _, tag in ipairs(tags) do
		-- 	assert(type(tag) == "string", "tag is not a string")
		-- end
	end)

	it("model_field_names returns a table of string", function()
		local field_names = require("anki.ankiconnect").model_field_names("Basic")
		assert(type(field_names) == "table", "field_names is not a table")
		for _, field_name in ipairs(field_names) do
			assert(type(field_name) == "string", "field_name is not a string")
		end
	end)

	it("add_note returns a number", function() end)

	it("add_note on duplicate returns ...", function() end)
	--
	-- TODO: test anki_connect_invoke parameters type
	-- TODO: handle errors when anki stopped
	----------------------------------------------------------------------------------------------------
end)

-- print(type(require("anki.ankiconnect").deck_names()))
-- print(vim.json.encode({
-- 	action = "deckNames",
-- 	version = 6,
-- 	params = {
--     name = ""
--   },
-- }))
