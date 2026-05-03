local EditorContext = require("anki.classes.editor_context")
local Field = require("anki.classes.field")
local Note = require("anki.classes.note")
local UI = require("anki.classes.ui")

local function make_field(name, bufnr)
	return Field:new({
		editor_context = { bufnr = bufnr, winid = bufnr * 10, tabid = bufnr * 100 },
		name = name,
	})
end

describe("EditorContext", function()
	it("creates an instance with valid fields", function()
		local ctx = EditorContext:new({ bufnr = 1, winid = 2, tabid = 3 })
		assert.are.equal(1, ctx.bufnr)
		assert.are.equal(2, ctx.winid)
		assert.are.equal(3, ctx.tabid)
	end)

	it("throws error when bufnr is missing", function()
		assert.has_error(function()
			EditorContext:new({ winid = 2, tabid = 3 })
		end)
	end)

	it("throws error when bufnr is not a number", function()
		assert.has_error(function()
			EditorContext:new({ bufnr = "bad", winid = 2, tabid = 3 })
		end)
	end)

	it("throws error when winid is missing", function()
		assert.has_error(function()
			EditorContext:new({ bufnr = 1, tabid = 3 })
		end)
	end)

	it("throws error when tabid is missing", function()
		assert.has_error(function()
			EditorContext:new({ bufnr = 1, winid = 2 })
		end)
	end)

	it("has a readable __tostring", function()
		local ctx = EditorContext:new({ bufnr = 10, winid = 20, tabid = 30 })
		local s = tostring(ctx)
		assert.is_true(s:find("EditorContext") ~= nil)
		assert.is_true(s:find("10") ~= nil)
		assert.is_true(s:find("20") ~= nil)
		assert.is_true(s:find("30") ~= nil)
	end)
end)

describe("Field", function()
	it("creates an instance with valid fields", function()
		local f = Field:new({
			editor_context = { bufnr = 1, winid = 2, tabid = 3 },
			name = "Front",
		})
		assert.are.equal("Front", f.name)
		assert.are.equal(1, f.editor_context.bufnr)
	end)

	it("auto-converts plain table editor_context to EditorContext", function()
		local f = Field:new({
			editor_context = { bufnr = 1, winid = 2, tabid = 3 },
			name = "Back",
		})
		assert.are.equal(EditorContext, getmetatable(f.editor_context).__index)
	end)

	it("preserves an existing EditorContext instance", function()
		local ctx = EditorContext:new({ bufnr = 5, winid = 6, tabid = 7 })
		local f = Field:new({ editor_context = ctx, name = "Text" })
		assert.are.equal(ctx, f.editor_context)
	end)

	it("throws error when editor_context is missing", function()
		assert.has_error(function()
			Field:new({ name = "Front" })
		end)
	end)

	it("throws error when name is missing", function()
		assert.has_error(function()
			Field:new({ editor_context = { bufnr = 1, winid = 2, tabid = 3 } })
		end)
	end)

	it("throws error when name is not a string", function()
		assert.has_error(function()
			Field:new({ editor_context = { bufnr = 1, winid = 2, tabid = 3 }, name = 42 })
		end)
	end)

	it("has a readable __tostring", function()
		local f = Field:new({
			editor_context = { bufnr = 99, winid = 88, tabid = 77 },
			name = "Front",
		})
		local s = tostring(f)
		assert.is_true(s:find("Field") ~= nil)
		assert.is_true(s:find("Front") ~= nil)
		assert.is_true(s:find("99") ~= nil)
	end)
end)

describe("Note", function()
	it("creates an instance with required fields", function()
		local n = Note:new({
			deck_name = "Default",
			model_name = "Basic",
			fields = { make_field("Front", 1) },
			tags = { bufnr = 50, winid = 51, tabid = 52 },
		})
		assert.are.equal("Default", n.deck_name)
		assert.are.equal("Basic", n.model_name)
		assert.are.equal(1, #n.fields)
	end)

	it("auto-converts tags plain table to EditorContext", function()
		local n = Note:new({
			deck_name = "Test",
			model_name = "Basic",
			fields = {},
			tags = { bufnr = 10, winid = 20, tabid = 30 },
		})
		assert.are.equal(EditorContext, getmetatable(n.tags).__index)
	end)

	it("preserves an existing EditorContext for tags", function()
		local tags = EditorContext:new({ bufnr = 5, winid = 6, tabid = 7 })
		local n = Note:new({
			deck_name = "Test",
			model_name = "Basic",
			fields = {},
			tags = tags,
		})
		assert.are.equal(tags, n.tags)
	end)

	it("throws error when deck_name is missing", function()
		assert.has_error(function()
			Note:new({ model_name = "Basic", fields = {} })
		end)
	end)

	it("throws error when model_name is missing", function()
		assert.has_error(function()
			Note:new({ deck_name = "Default", fields = {} })
		end)
	end)

	it("throws error when fields is missing", function()
		assert.has_error(function()
			Note:new({ deck_name = "Default", model_name = "Basic" })
		end)
	end)

	it("throws error when deck_name is not a string", function()
		assert.has_error(function()
			Note:new({ deck_name = 123, model_name = "Basic", fields = {} })
		end)
	end)

	it("throws error when model_name is not a string", function()
		assert.has_error(function()
			Note:new({ deck_name = "Default", model_name = 123, fields = {} })
		end)
	end)

	describe("find_field_by_name", function()
		it("returns the index of a field when found", function()
			local n = Note:new({
				deck_name = "Default",
				model_name = "Basic",
				fields = {
					make_field("Front", 1),
					make_field("Back", 2),
				},
				tags = { bufnr = 3, winid = 4, tabid = 5 },
			})
			assert.are.equal(1, n:find_field_by_name("Front"))
			assert.are.equal(2, n:find_field_by_name("Back"))
		end)

		it("returns nil when the field is not found", function()
			local n = Note:new({
				deck_name = "Default",
				model_name = "Basic",
				fields = { make_field("Front", 1) },
				tags = { bufnr = 2, winid = 3, tabid = 4 },
			})
			assert.is_nil(n:find_field_by_name("Nonexistent"))
		end)
	end)

	it("has a readable __tostring", function()
		local n = Note:new({
			deck_name = "MyDeck",
			model_name = "Basic",
			fields = { make_field("Front", 1), make_field("Back", 2) },
			tags = { bufnr = 3, winid = 4, tabid = 5 },
			id = 42,
		})
		local s = tostring(n)
		assert.is_true(s:find("Note") ~= nil)
		assert.is_true(s:find("MyDeck") ~= nil)
		assert.is_true(s:find("Basic") ~= nil)
		assert.is_true(s:find("2") ~= nil)
	end)
end)

describe("UI", function()
	it("creates an instance with provided fields", function()
		local ui = UI:new({
			win_id = 1,
			deck_buf_id = 2,
			note_buf_id = 3,
			editor_win_id = 4,
			notes = { "note1" },
			decks = { "deck1" },
			current_filter = nil,
		})
		assert.are.equal(1, ui.win_id)
		assert.are.equal(2, ui.deck_buf_id)
		assert.are.equal(3, ui.note_buf_id)
		assert.are.equal(4, ui.editor_win_id)
		assert.are.equal(1, #ui.notes)
		assert.are.equal(1, #ui.decks)
	end)

	it("creates an instance with empty tables for notes and decks", function()
		local ui = UI:new({ notes = {}, decks = {} })
		assert.are.equal(0, #ui.notes)
		assert.are.equal(0, #ui.decks)
		assert.is_nil(ui.win_id)
		assert.is_nil(ui.current_filter)
	end)

	it("has a readable __tostring", function()
		local ui = UI:new({ win_id = 100, notes = {}, decks = {} })
		local s = tostring(ui)
		assert.is_true(s:find("UI") ~= nil)
		assert.is_true(s:find("100") ~= nil)
	end)
end)
