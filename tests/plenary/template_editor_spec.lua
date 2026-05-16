local anki_state = require("anki.state")

describe("anki.state with template support", function()
	before_each(function()
		anki_state.counter = 0
		anki_state.current_note = nil
		anki_state.current_template = {}
	end)

	describe("current_template", function()
		it("is an empty table by default", function()
			assert.are.same({}, anki_state.current_template)
		end)

		it("can store a template state keyed by tabpage id", function()
			anki_state.current_template[1] = {
				model_name = "Basic",
				card_name = "Card 1",
				cards = {
					["Card 1"] = { Front = "{{Front}}", Back = "{{FrontSide}}\n\n<hr id=answer>\n\n{{Back}}" },
				},
				css = ".card { font-family: arial; }",
				front_bufnr = 1,
				back_bufnr = 2,
				styling_bufnr = 3,
				tabid = 1,
			}
			assert.is_not_nil(anki_state.current_template[1])
			assert.are.equal("Basic", anki_state.current_template[1].model_name)
			assert.are.equal("Card 1", anki_state.current_template[1].card_name)
			assert.are.equal(1, anki_state.current_template[1].front_bufnr)
			assert.are.equal(2, anki_state.current_template[1].back_bufnr)
			assert.are.equal(3, anki_state.current_template[1].styling_bufnr)
			assert.are.equal(1, anki_state.current_template[1].tabid)
		end)

		it("can be cleared by setting the entry to nil", function()
			anki_state.current_template[1] = {
				model_name = "Basic",
				card_name = "Card 1",
				cards = {},
				css = "",
				front_bufnr = 1,
				back_bufnr = 2,
				styling_bufnr = 3,
				tabid = 1,
			}
			assert.is_not_nil(anki_state.current_template[1])
			anki_state.current_template[1] = nil
			assert.is_nil(anki_state.current_template[1])
		end)

		it("stores cards as a table mapping card names to template data", function()
			local cards = {
				["Card 1"] = { Front = "{{Front}}", Back = "{{Back}}" },
				["Card 2"] = { Front = "{{Back}}", Back = "{{Front}}" },
			}
			anki_state.current_template[1] = {
				model_name = "Basic (and reversed card)",
				card_name = "Card 1",
				cards = cards,
				css = ".card {}",
				front_bufnr = 1,
				back_bufnr = 2,
				styling_bufnr = 3,
				tabid = 1,
			}
			assert.is_not_nil(anki_state.current_template[1].cards["Card 1"])
			assert.is_not_nil(anki_state.current_template[1].cards["Card 2"])
			assert.are.equal("{{Front}}", anki_state.current_template[1].cards["Card 1"].Front)
			assert.are.equal("{{Back}}", anki_state.current_template[1].cards["Card 2"].Front)
		end)

		it("supports multiple template editors simultaneously", function()
			anki_state.current_template[1] = {
				model_name = "Basic",
				card_name = "Card 1",
				cards = {},
				css = "",
				front_bufnr = 1,
				back_bufnr = 2,
				styling_bufnr = 3,
				tabid = 1,
			}
			anki_state.current_template[2] = {
				model_name = "Cloze",
				card_name = "Cloze",
				cards = {},
				css = "",
				front_bufnr = 4,
				back_bufnr = 5,
				styling_bufnr = 6,
				tabid = 2,
			}
			assert.are.equal("Basic", anki_state.current_template[1].model_name)
			assert.are.equal("Cloze", anki_state.current_template[2].model_name)
			anki_state.current_template[1] = nil
			assert.is_nil(anki_state.current_template[1])
			assert.is_not_nil(anki_state.current_template[2])
		end)
	end)
end)
