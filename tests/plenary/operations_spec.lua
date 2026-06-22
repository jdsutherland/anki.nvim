local operations = require("anki.ui.operations")
local anki_state = require("anki.state")
local config = require("anki.config")

describe("anki.ui.operations", function()
	before_each(function()
		config.setup({})
		-- Reset UI state to defaults.
		anki_state.ui.view_mode = "notes"
		anki_state.ui.notes = {}
		anki_state.ui.cards = {}
		anki_state.ui.current_filter = nil
	end)

	describe("HEADER_LINES", function()
		it("is a positive integer constant", function()
			assert.is_number(operations.HEADER_LINES)
			assert.is_true(operations.HEADER_LINES >= 1)
		end)
	end)

	describe("toggle_view_mode", function()
		it("flips view_mode between notes and cards", function()
			assert.are.equal("notes", anki_state.ui.view_mode)
			-- Stub update_notes_view to avoid hitting AnkiConnect.
			local saved = operations.refresh_notes
			operations.refresh_notes = function() end
			operations.toggle_view_mode()
			assert.are.equal("cards", anki_state.ui.view_mode)
			operations.toggle_view_mode()
			assert.are.equal("notes", anki_state.ui.view_mode)
			operations.refresh_notes = saved
		end)
	end)

	describe("search_notes", function()
		it("updates current_filter when a query is entered", function()
			local saved_input = vim.ui.input
			vim.ui.input = function(opts, on_result)
				on_result("deck:Foo")
			end
			local saved = operations.refresh_notes
			operations.refresh_notes = function() end
			operations.search_notes()
			assert.are.equal("deck:Foo", anki_state.ui.current_filter)
			operations.refresh_notes = saved
			vim.ui.input = saved_input
		end)

		it("does not update filter when input is cancelled", function()
			anki_state.ui.current_filter = "deck:Original"
			local saved_input = vim.ui.input
			vim.ui.input = function(opts, on_result)
				on_result(nil)
			end
			local saved = operations.refresh_notes
			operations.refresh_notes = function() end
			operations.search_notes()
			assert.are.equal("deck:Original", anki_state.ui.current_filter)
			operations.refresh_notes = saved
			vim.ui.input = saved_input
		end)
	end)

	describe("show_all_notes", function()
		it("resets view_mode to notes", function()
			anki_state.ui.view_mode = "cards"
			-- Stub the async fetch by stubbing refresh_notes; show_all_notes
			-- will still call find_notes asynchronously but we only assert
			-- the mode flip which happens synchronously.
			local saved = operations.refresh_notes
			operations.refresh_notes = function() end
			anki_state.ui.note_buf_id = nil
			operations.show_all_notes()
			assert.are.equal("notes", anki_state.ui.view_mode)
			assert.are.equal("deck:*", anki_state.ui.current_filter)
			operations.refresh_notes = saved
		end)
	end)
end)

describe("anki.classes.UI new fields", function()
	local UI = require("anki.classes.ui")

	it("initializes cards to an empty table", function()
		local ui = UI:new({})
		assert.is_table(ui.cards)
		assert.are.equal(0, #ui.cards)
	end)

	it("defaults view_mode to notes when not provided", function()
		local ui = UI:new({})
		assert.are.equal("notes", ui.view_mode)
	end)

	it("accepts view_mode and cards in constructor", function()
		local ui = UI:new({ view_mode = "cards", cards = { { cardId = 1 } } })
		assert.are.equal("cards", ui.view_mode)
		assert.are.equal(1, #ui.cards)
	end)
end)
