---
--- anki.template_editor
---
--- Provides functions for opening, saving, pulling, and closing a card template
--- editor in a new Neovim tab. The editor shows three split panes:
---   - Front template (HTML)
---   - Back template (HTML)
---   - Styling (CSS)
---
--- For models with multiple card templates (e.g., "Card 1", "Card 2"),
--- use switch_card() to select which card's Front/Back is displayed.
---
--- Multiple template editors can be open simultaneously; state is tracked
--- per tabpage in anki_state.current_template.
---
local anki_state = require("anki.state")
local ankiconnect = require("anki.ankiconnect")
local notification = require("anki.notification")
local utils = require("anki.utils")
local config = require("anki.config")

local M = {}

---
--- Returns the template editor state for the current tabpage, or nil if none.
---
---@return AnkiTemplateState|nil
local function get_current_template()
	local tabid = vim.api.nvim_get_current_tabpage()
	return anki_state.current_template[tabid]
end

---
--- Opens the template editor for the given model in a new tab.
--- Fetches modelTemplates and modelStyling from AnkiConnect and
--- populates three split panes (Front, Back, Styling).
---
--- If a template editor for the same model is already open, switches to that tab.
---
---@param model_name string The name of the model to edit templates for.
function M.open(model_name)
	if type(model_name) ~= "string" then
		error("[anki.nvim][template_editor] open: model_name must be a string")
	end

	for _, tmpl in pairs(anki_state.current_template) do
		if tmpl.model_name == model_name then
			if vim.api.nvim_tabpage_is_valid(tmpl.tabid) then
				vim.api.nvim_set_current_tabpage(tmpl.tabid)
			else
				anki_state.current_template[tmpl.tabid] = nil
			end
			return
		end
	end

	local function fetch_and_open(templates, styling)
		vim.schedule(function()
			local card_names = {}
			for name, _ in pairs(templates or {}) do
				table.insert(card_names, name)
			end
			table.sort(card_names)

			if #card_names == 0 then
				notification.warn("[anki.nvim][template_editor] Model has no card templates")
				return
			end

			local first_card = card_names[1]
			local first_front = (templates and templates[first_card] and templates[first_card].Front) or ""
			local first_back = (templates and templates[first_card] and templates[first_card].Back) or ""
			local css = (styling and styling.css) or ""

			vim.cmd("tabnew")
			local tabid = vim.api.nvim_get_current_tabpage()

			local front_buf = vim.api.nvim_create_buf(false, true)
			local back_buf = vim.api.nvim_create_buf(false, true)
			local styling_buf = vim.api.nvim_create_buf(false, true)

			vim.api.nvim_buf_set_name(front_buf, "anki-template://" .. tabid .. "/Front_" .. model_name)
			vim.api.nvim_buf_set_name(back_buf, "anki-template://" .. tabid .. "/Back_" .. model_name)
			vim.api.nvim_buf_set_name(styling_buf, "anki-template://" .. tabid .. "/Styling_" .. model_name)

			vim.api.nvim_set_option_value("filetype", "html", { buf = front_buf })
			vim.api.nvim_set_option_value("filetype", "html", { buf = back_buf })
			vim.api.nvim_set_option_value("filetype", "css", { buf = styling_buf })

			vim.api.nvim_buf_set_lines(front_buf, 0, -1, false, utils.split(first_front, "\n"))
			vim.api.nvim_buf_set_lines(back_buf, 0, -1, false, utils.split(first_back, "\n"))
			vim.api.nvim_buf_set_lines(styling_buf, 0, -1, false, utils.split(css, "\n"))

			local win_front = vim.api.nvim_get_current_win()
			vim.api.nvim_win_set_buf(win_front, front_buf)

			vim.cmd("split")
			local win_back = vim.api.nvim_get_current_win()
			vim.api.nvim_win_set_buf(win_back, back_buf)

			vim.cmd("split")
			local win_styling = vim.api.nvim_get_current_win()
			vim.api.nvim_win_set_buf(win_styling, styling_buf)

			anki_state.current_template[tabid] = {
				model_name = model_name,
				card_name = first_card,
				cards = templates or {},
				css = css,
				front_bufnr = front_buf,
				back_bufnr = back_buf,
				styling_bufnr = styling_buf,
				tabid = tabid,
			}

			M.setup_keymaps(front_buf)
			M.setup_keymaps(back_buf)
			M.setup_keymaps(styling_buf)

			notification.info(
				"[anki.nvim][template_editor] Editing model '" .. model_name .. "' — Card: " .. first_card
			)
		end)
	end

	utils.async_safe_call(ankiconnect.model_templates, { model_name }, function(templates, err1)
		if err1 or not templates then
			notification.error("[anki.nvim][template_editor] Failed to fetch model templates")
			return
		end
		utils.async_safe_call(ankiconnect.model_styling, { model_name }, function(styling, err2)
			if err2 or not styling then
				notification.error("[anki.nvim][template_editor] Failed to fetch model styling")
				return
			end
			fetch_and_open(templates, styling)
		end)
	end)
end

---
--- Sets up buffer-local keymaps for a template editor buffer.
---
---@param bufnr integer Buffer number to set keymaps on.
function M.setup_keymaps(bufnr)
	local mappings = config.options.mappings.template
	local keymap_cmds = {
		save_template = string.format("<Cmd>lua require('anki.template_editor').save()<CR>"),
		pull_template = string.format("<Cmd>lua require('anki.template_editor').pull()<CR>"),
		switch_card = string.format("<Cmd>lua require('anki.template_editor').switch_card()<CR>"),
		close_template = string.format("<Cmd>lua require('anki.template_editor').close()<CR>"),
		show_help = string.format("<Cmd>lua require('anki.ui.help').show_help('templates')<CR>"),
	}

	for action, key in pairs(mappings) do
		if keymap_cmds[action] then
			vim.api.nvim_buf_set_keymap(bufnr, "n", key, keymap_cmds[action], { noremap = true, silent = true })
		end
	end
end

---
--- Saves the current template content (Front, Back, Styling) to Anki.
--- Sends both updateModelTemplates and updateModelStyling in sequence.
---
function M.save()
	local tmpl = get_current_template()
	if not tmpl then
		notification.warn("[anki.nvim][template_editor] No template editor is open")
		return
	end

	local front_lines = vim.api.nvim_buf_get_lines(tmpl.front_bufnr, 0, -1, false)
	local back_lines = vim.api.nvim_buf_get_lines(tmpl.back_bufnr, 0, -1, false)
	local styling_lines = vim.api.nvim_buf_get_lines(tmpl.styling_bufnr, 0, -1, false)

	local front_content = table.concat(front_lines, "\n")
	local back_content = table.concat(back_lines, "\n")
	local css_content = table.concat(styling_lines, "\n")

	tmpl.cards[tmpl.card_name] = {
		Front = front_content,
		Back = back_content,
	}
	tmpl.css = css_content

	utils.async_safe_call(
		ankiconnect.update_model_templates,
		{ { name = tmpl.model_name, templates = tmpl.cards } },
		function(_, err1)
			if err1 then
				notification.error("[anki.nvim][template_editor] Failed to save templates")
				return
			end
			utils.async_safe_call(
				ankiconnect.update_model_styling,
				{ { name = tmpl.model_name, css = css_content } },
				function(_, err2)
					if err2 then
						notification.error("[anki.nvim][template_editor] Failed to save styling")
						return
					end
					notification.info(
						"[anki.nvim][template_editor] Saved template for model '"
							.. tmpl.model_name
							.. "' — Card: "
							.. tmpl.card_name
					)
				end
			)
		end
	)
end

---
--- Pulls the latest template and styling content from Anki and
--- overwrites the editor buffers.
---
function M.pull()
	local tmpl = get_current_template()
	if not tmpl then
		notification.warn("[anki.nvim][template_editor] No template editor is open")
		return
	end

	local model_name = tmpl.model_name
	local card_name = tmpl.card_name

	utils.async_safe_call(ankiconnect.model_templates, { model_name }, function(templates, err1)
		if err1 or not templates then
			notification.error("[anki.nvim][template_editor] Failed to pull model templates")
			return
		end
		utils.async_safe_call(ankiconnect.model_styling, { model_name }, function(styling, err2)
			if err2 or not styling then
				notification.error("[anki.nvim][template_editor] Failed to pull model styling")
				return
			end
			vim.schedule(function()
				local card_data = templates[card_name]
				if not card_data then
					local card_names = {}
					for name, _ in pairs(templates) do
						table.insert(card_names, name)
					end
					table.sort(card_names)
					if #card_names > 0 then
						card_name = card_names[1]
						card_data = templates[card_name]
					end
				end

				if not card_data then
					notification.error("[anki.nvim][template_editor] No card templates found on pull")
					return
				end

				local front_content = card_data.Front or ""
				local back_content = card_data.Back or ""
				local css = styling.css or ""

				if vim.api.nvim_buf_is_valid(tmpl.front_bufnr) then
					vim.api.nvim_buf_set_lines(tmpl.front_bufnr, 0, -1, false, utils.split(front_content, "\n"))
				end
				if vim.api.nvim_buf_is_valid(tmpl.back_bufnr) then
					vim.api.nvim_buf_set_lines(tmpl.back_bufnr, 0, -1, false, utils.split(back_content, "\n"))
				end
				if vim.api.nvim_buf_is_valid(tmpl.styling_bufnr) then
					vim.api.nvim_buf_set_lines(tmpl.styling_bufnr, 0, -1, false, utils.split(css, "\n"))
				end

				tmpl.cards = templates
				tmpl.card_name = card_name
				tmpl.css = css

				notification.info(
					"[anki.nvim][template_editor] Pulled template for model '"
						.. model_name
						.. "' — Card: "
						.. card_name
				)
			end)
		end)
	end)
end

---
--- Switches the displayed card template when the model has multiple cards.
--- Prompts the user to select a card name, then updates the Front and Back buffers.
---
function M.switch_card()
	local tmpl = get_current_template()
	if not tmpl then
		notification.warn("[anki.nvim][template_editor] No template editor is open")
		return
	end

	local card_names = {}
	for name, _ in pairs(tmpl.cards) do
		table.insert(card_names, name)
	end
	table.sort(card_names)

	if #card_names <= 1 then
		notification.info("[anki.nvim][template_editor] This model only has one card template")
		return
	end

	vim.ui.select(card_names, { prompt = "Select card template" }, function(selected)
		if not selected then
			return
		end

		local card_data = tmpl.cards[selected]
		if not card_data then
			notification.error("[anki.nvim][template_editor] Card template not found: " .. selected)
			return
		end

		if vim.api.nvim_buf_is_valid(tmpl.front_bufnr) then
			vim.api.nvim_buf_set_lines(tmpl.front_bufnr, 0, -1, false, utils.split(card_data.Front or "", "\n"))
		end
		if vim.api.nvim_buf_is_valid(tmpl.back_bufnr) then
			vim.api.nvim_buf_set_lines(tmpl.back_bufnr, 0, -1, false, utils.split(card_data.Back or "", "\n"))
		end

		tmpl.card_name = selected
		notification.info("[anki.nvim][template_editor] Switched to card: " .. selected)
	end)
end

---
--- Closes the template editor tab and cleans up buffers and state.
---
function M.close()
	local tmpl = get_current_template()
	if not tmpl then
		notification.warn("[anki.nvim][template_editor] No template editor is open")
		return
	end

	if vim.api.nvim_buf_is_valid(tmpl.front_bufnr) then
		vim.api.nvim_buf_delete(tmpl.front_bufnr, { force = true })
	end
	if vim.api.nvim_buf_is_valid(tmpl.back_bufnr) then
		vim.api.nvim_buf_delete(tmpl.back_bufnr, { force = true })
	end
	if vim.api.nvim_buf_is_valid(tmpl.styling_bufnr) then
		vim.api.nvim_buf_delete(tmpl.styling_bufnr, { force = true })
	end

	if vim.api.nvim_tabpage_is_valid(tmpl.tabid) then
		local tab_number = vim.api.nvim_tabpage_get_number(tmpl.tabid)
		vim.cmd("tabclose " .. tab_number)
	end

	anki_state.current_template[tmpl.tabid] = nil
	notification.info("[anki.nvim][template_editor] Template editor closed")
end

return M
