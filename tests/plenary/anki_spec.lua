local ankiconnect = require("anki.ankiconnect")
local config = require("anki.config")
config.setup()

describe("anki.ankiconnect", function()
	local test_deck_name = "test-deck-for-anki.nvim"
	local note_id

	before_each(function()
		ankiconnect.create_deck(test_deck_name)
	end)

	after_each(function()
		ankiconnect.delete_decks({ test_deck_name })
	end)

	it("should create a deck and it should be listed in deck_names", function()
		local decks = ankiconnect.deck_names()
		local found = false
		for _, deck in ipairs(decks.result) do
			if deck == test_deck_name then
				found = true
				break
			end
		end
		assert.is_true(found)
	end)

	it("should get model_names", function()
		local models = ankiconnect.model_names()
		assert.is_true(#models.result > 0)
	end)

	it("should get model_field_names for Basic model", function()
		local fields = ankiconnect.model_field_names("Basic")
		assert.are.same({ "Front", "Back" }, fields.result)
	end)

	it("should add and delete a note", function()
		local result = ankiconnect.add_note(test_deck_name, "Basic", { Front = "test", Back = "test" }, { "test-tag" })
		note_id = result.result
		assert.is_not_nil(note_id)

		local notes = ankiconnect.find_notes("deck:" .. test_deck_name)
		assert.are.equal(1, #notes.result)
		assert.are.equal(note_id, notes.result[1])

		local info = ankiconnect.notes_info({ note_id })
		assert.are.equal(note_id, info.result[1].noteId)

		local update_result = ankiconnect.update_note(note_id, { Front = "updated" })
		assert.is_equal(vim.NIL, update_result.error)

		local delete_result = ankiconnect.delete_notes({ note_id })
		assert.is_equal(vim.NIL, delete_result.error)

		notes = ankiconnect.find_notes("deck:" .. test_deck_name)
		assert.are.equal(0, #notes.result)
	end)
end)
