local config = require("anki.config")

describe("anki.config", function()
	before_each(function()
		config.setup()
	end)

	describe("defaults", function()
		it("has expected top-level keys", function()
			assert.is_not_nil(config.defaults.url)
			assert.is_not_nil(config.defaults.timeout)
			assert.is_not_nil(config.defaults.prefix)
			assert.is_not_nil(config.defaults.default_mappings)
			assert.is_not_nil(config.defaults.gui_browse_enabled)
			assert.is_not_nil(config.defaults.create_user_commands)
			assert.is_not_nil(config.defaults.mappings)
			assert.is_not_nil(config.defaults.note_formatter)
		end)

		it("has expected default values", function()
			assert.are.equal("http://localhost:8765", config.defaults.url)
			assert.are.equal(500, config.defaults.timeout)
			assert.are.equal("<leader>a", config.defaults.prefix)
			assert.is_true(config.defaults.default_mappings)
			assert.is_true(config.defaults.gui_browse_enabled)
			assert.is_true(config.defaults.create_user_commands)
		end)

		it("has deck mapping keys", function()
			local deck = config.defaults.mappings.deck
			assert.is_not_nil(deck.show_help)
			assert.is_not_nil(deck.close)
			assert.is_not_nil(deck.select_deck)
			assert.is_not_nil(deck.delete_deck)
			assert.is_not_nil(deck.create_deck)
			assert.is_not_nil(deck.add_note)
			assert.is_not_nil(deck.rename_deck)
			assert.is_not_nil(deck.gui_deck)
			assert.is_not_nil(deck.refresh_decks)
			assert.is_not_nil(deck.switch_profile)
		end)

		it("has note mapping keys", function()
			local note = config.defaults.mappings.note
			assert.is_not_nil(note.show_help)
			assert.is_not_nil(note.close)
			assert.is_not_nil(note.edit_note)
			assert.is_not_nil(note.delete_note)
			assert.is_not_nil(note.gui_note)
			assert.is_not_nil(note.show_all_notes)
			assert.is_not_nil(note.refresh_notes)
			assert.is_not_nil(note.move_note_to_deck)
		end)

		it("has editor mapping keys", function()
			local editor = config.defaults.mappings.editor
			assert.is_not_nil(editor.send_note)
			assert.is_not_nil(editor.pull_note)
			assert.is_not_nil(editor.delete_note)
			assert.is_not_nil(editor.kill_note)
			assert.is_not_nil(editor.show_help)
		end)

		it("has a note_formatter that formats note fields", function()
			local note = {
				fields = {
					Front = { value = "What is 2+2?" },
				},
			}
			local result = config.defaults.note_formatter(note)
			assert.are.equal(" [Front]> What is 2+2?", result)
		end)

		it("has a note_formatter that collapses newlines in field values", function()
			local note = {
				fields = {
					Text = { value = "line1\nline2\nline3" },
				},
			}
			local result = config.defaults.note_formatter(note)
			assert.are.equal(" [Text]> line1 line2 line3", result)
		end)

		it("has a note_formatter that collapses carriage returns in field values", function()
			local note = {
				fields = {
					Text = { value = "line1\r\nline2" },
				},
			}
			local result = config.defaults.note_formatter(note)
			assert.are.equal(" [Text]> line1  line2", result)
		end)
	end)

	describe("setup", function()
		it("sets options to defaults when called with nil", function()
			config.setup(nil)
			assert.are.equal(config.defaults.url, config.options.url)
			assert.are.equal(config.defaults.timeout, config.options.timeout)
		end)

		it("sets options to defaults when called without arguments", function()
			config.setup()
			assert.are.equal(config.defaults.url, config.options.url)
		end)

		it("deep-merges user overrides into options", function()
			config.setup({ url = "http://custom:1234", timeout = 1000 })
			assert.are.equal("http://custom:1234", config.options.url)
			assert.are.equal(1000, config.options.timeout)
			assert.are.equal(config.defaults.prefix, config.options.prefix)
		end)

		it("deep-merges nested mapping overrides", function()
			config.setup({ mappings = { deck = { create_deck = "N" } } })
			assert.are.equal("N", config.options.mappings.deck.create_deck)
			assert.are.equal(config.defaults.mappings.deck.close, config.options.mappings.deck.close)
			assert.are.equal(config.defaults.mappings.note.edit_note, config.options.mappings.note.edit_note)
		end)

		it("throws error when opts is not a table or nil", function()
			assert.has_error(function()
				config.setup("invalid")
			end, "[anki.nvim][config] setup: opts must be a table or nil")

			assert.has_error(function()
				config.setup(42)
			end, "[anki.nvim][config] setup: opts must be a table or nil")
		end)

		it("overrides note_formatter when provided", function()
			local call_log = {}
			local custom_formatter = function(note)
				table.insert(call_log, note)
				return "custom"
			end
			config.setup({ note_formatter = custom_formatter })

			local note = {
				fields = {
					Front = { value = "hello" },
				},
			}
			local result = config.options.note_formatter(note)
			assert.are.equal("custom", result)
			assert.are.equal(1, #call_log)
			assert.are.same(note, call_log[1])
		end)
	end)
end)
