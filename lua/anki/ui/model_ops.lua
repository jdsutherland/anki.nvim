local utils = require("anki.utils")
local ankiconnect = require("anki.ankiconnect")
local notification = require("anki.notification")
local template_editor = require("anki.template_editor")

local M = {}

---
--- Opens the template editor for a model selected by the user.
--- Lists all available models via AnkiConnect and prompts for selection.
---
function M.edit_model_templates()
	utils.async_safe_call(ankiconnect.model_names, nil, function(model_names, error)
		if error or not model_names then
			notification.error("[anki.nvim][model_ops] Failed to fetch model names")
			return
		end
		if #model_names == 0 then
			notification.warn("[anki.nvim][model_ops] No models found")
			return
		end

		vim.ui.select(model_names, { prompt = "Select a model to edit templates" }, function(selected)
			if not selected then
				return
			end
			template_editor.open(selected)
		end)
	end)
end

---
--- Creates a new model (note type) in Anki via an interactive flow:
---   1. Prompt for model name
---   2. Prompt for comma-separated field names
---   3. Prompt for number of cards
---   4. Prompt for each card name
---   5. Create the model with default templates, then open the template editor
---
function M.create_model()
	vim.ui.input({ prompt = "New model name: " }, function(model_name)
		if not model_name or model_name == "" then
			return
		end

		vim.ui.input({ prompt = "Field names (comma-separated): " }, function(fields_input)
			if not fields_input or fields_input == "" then
				return
			end

			local fields = {}
			for field in string.gmatch(fields_input, "([^,]+)") do
				local trimmed = field:match("^%s*(.-)%s*$")
				if trimmed ~= "" then
					table.insert(fields, trimmed)
				end
			end

			if #fields == 0 then
				notification.error("[anki.nvim][model_ops] At least one field name is required")
				return
			end

			vim.ui.input({ prompt = "Number of card templates (default: 1): " }, function(num_input)
				local num_cards = tonumber(num_input) or 1
				if num_cards < 1 then
					num_cards = 1
				end

				local card_names_remaining = num_cards
				local card_names = {}

				local function prompt_card_name(idx)
					if idx > num_cards then
						M._do_create_model(model_name, fields, card_names)
						return
					end

					local default_name = "Card " .. idx
					vim.ui.input(
						{ prompt = "Card template " .. idx .. " name (default: " .. default_name .. "): " },
						function(name)
							if not name or name == "" then
								name = default_name
							end
							table.insert(card_names, name)
							prompt_card_name(idx + 1)
						end
					)
				end

				prompt_card_name(1)
			end)
		end)
	end)
end

---
--- Internal function that creates the model via AnkiConnect and opens the template editor.
---
---@param model_name string The model name.
---@param fields table List of field names in order.
---@param card_names table List of card template names.
function M._do_create_model(model_name, fields, card_names)
	local card_templates = {}
	local first_field = fields[1]
	for i, card_name in ipairs(card_names) do
		local template = {
			Name = card_name,
			Front = "{{" .. first_field .. "}}",
			Back = "{{FrontSide}}\n\n<hr id=answer>\n\n{{" .. (fields[2] or first_field) .. "}}",
		}
		table.insert(card_templates, template)
	end

	utils.async_safe_call(ankiconnect.create_model, { model_name, fields, card_templates }, function(result, error)
		if error or not result then
			notification.error("[anki.nvim][model_ops] Failed to create model: " .. tostring(error))
			return
		end
		notification.info("[anki.nvim][model_ops] Created model '" .. model_name .. "'")
		template_editor.open(model_name)
	end)
end

return M
