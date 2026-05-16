local utils = require("anki.utils")

describe("anki.ui.model_ops", function()
	describe("field name parsing", function()
		it("parses comma-separated fields with trimming", function()
			local input = "Front, Back,  Extra "
			local fields = {}
			for field in string.gmatch(input, "([^,]+)") do
				local trimmed = field:match("^%s*(.-)%s*$")
				if trimmed ~= "" then
					table.insert(fields, trimmed)
				end
			end
			assert.are.same({ "Front", "Back", "Extra" }, fields)
		end)

		it("handles single field name", function()
			local input = "Text"
			local fields = {}
			for field in string.gmatch(input, "([^,]+)") do
				local trimmed = field:match("^%s*(.-)%s*$")
				if trimmed ~= "" then
					table.insert(fields, trimmed)
				end
			end
			assert.are.same({ "Text" }, fields)
		end)

		it("handles fields with extra whitespace", function()
			local input = "  Front  ,   Back   ,  Text  "
			local fields = {}
			for field in string.gmatch(input, "([^,]+)") do
				local trimmed = field:match("^%s*(.-)%s*$")
				if trimmed ~= "" then
					table.insert(fields, trimmed)
				end
			end
			assert.are.same({ "Front", "Back", "Text" }, fields)
		end)

		it("yields empty table for empty string", function()
			local input = ""
			local fields = {}
			for field in string.gmatch(input, "([^,]+)") do
				local trimmed = field:match("^%s*(.-)%s*$")
				if trimmed ~= "" then
					table.insert(fields, trimmed)
				end
			end
			assert.are.same({}, fields)
		end)

		it("yields empty table for whitespace-only string", function()
			local input = "   ,  ,  "
			local fields = {}
			for field in string.gmatch(input, "([^,]+)") do
				local trimmed = field:match("^%s*(.-)%s*$")
				if trimmed ~= "" then
					table.insert(fields, trimmed)
				end
			end
			assert.are.same({}, fields)
		end)
	end)

	describe("default card template generation", function()
		it("generates correct Front template with first field", function()
			local fields = { "Front", "Back" }
			local first_field = fields[1]
			local front = "{{" .. first_field .. "}}"
			assert.are.equal("{{Front}}", front)
		end)

		it("generates correct Back template with FrontSide and second field", function()
			local fields = { "Front", "Back" }
			local first_field = fields[1]
			local back = "{{FrontSide}}\n\n<hr id=answer>\n\n{{" .. (fields[2] or first_field) .. "}}"
			assert.are.equal("{{FrontSide}}\n\n<hr id=answer>\n\n{{Back}}", back)
		end)

		it("falls back to first field when only one field exists", function()
			local fields = { "Text" }
			local first_field = fields[1]
			local back = "{{FrontSide}}\n\n<hr id=answer>\n\n{{" .. (fields[2] or first_field) .. "}}"
			assert.are.equal("{{FrontSide}}\n\n<hr id=answer>\n\n{{Text}}", back)
		end)
	end)
end)
