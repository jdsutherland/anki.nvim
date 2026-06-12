local config = require("anki.config")
local help = require("anki.ui.help")

local function get_help_lines(context)
	local bufnr = nil
	local saved_open_win = vim.api.nvim_open_win

	vim.api.nvim_open_win = function(buffer, enter, opts)
		bufnr = buffer
		return saved_open_win(buffer, enter, opts)
	end

	local ok, err = pcall(help.show_help, context)

	local lines = {}
	if bufnr and vim.api.nvim_buf_is_valid(bufnr) then
		lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
		vim.api.nvim_buf_delete(bufnr, { force = true })
	end

	vim.api.nvim_open_win = saved_open_win

	if not ok then
		return nil, err
	end
	return lines
end

local function cleanup_help_buffers()
	for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
		if vim.api.nvim_buf_is_valid(bufnr) then
			local name = vim.api.nvim_buf_get_name(bufnr)
			if name:find("Anki Help") then
				vim.api.nvim_buf_delete(bufnr, { force = true })
			end
		end
	end
end

describe("anki.ui.help", function()
	before_each(function()
		config.setup({})
		cleanup_help_buffers()
	end)

	describe("show_help for decks", function()
		it("does not error", function()
			local _, err = get_help_lines("decks")
			assert.is_nil(err)
		end)

		it("returns help lines referencing deck mappings", function()
			local lines, err = get_help_lines("decks")
			assert.is_nil(err)
			assert.is_table(lines)
			assert.is_true(#lines > 0)

			local found = {}
			for _, line in ipairs(lines) do
				found[line] = true
			end
			local m = config.options.mappings.deck
			assert.is_true(found[m.show_help .. " - Show this help window"] ~= nil)
			assert.is_true(found[m.close .. " - Close the Anki UI tab"] ~= nil)
			assert.is_true(found[m.select_deck .. " - Select a deck and show its notes"] ~= nil)
		end)
	end)

	describe("show_help for notes", function()
		it("does not error", function()
			local _, err = get_help_lines("notes")
			assert.is_nil(err)
		end)

		it("returns help lines referencing note mappings", function()
			local lines, err = get_help_lines("notes")
			assert.is_nil(err)
			assert.is_table(lines)

			local found = {}
			for _, line in ipairs(lines) do
				found[line] = true
			end
			local m = config.options.mappings.note
			assert.is_true(found[m.show_help .. " - Show this help window"] ~= nil)
			assert.is_true(found[m.close .. " - Close the Anki UI tab"] ~= nil)
			assert.is_true(found[m.edit_note .. " - Edit note"] ~= nil)
		end)
	end)

	describe("show_help for editor", function()
		it("does not error", function()
			local _, err = get_help_lines("editor")
			assert.is_nil(err)
		end)

		it("returns help lines referencing editor mappings", function()
			local lines, err = get_help_lines("editor")
			assert.is_nil(err)
			assert.is_table(lines)

			local found = {}
			for _, line in ipairs(lines) do
				found[line] = true
			end
			local m = config.options.mappings.editor
			assert.is_true(found[m.show_help .. " - Show this help window"] ~= nil)
			assert.is_true(found[m.send_note .. " - Write/Send note to Anki"] ~= nil)
			assert.is_true(found[m.close .. " - Close the note editor"] ~= nil)
			assert.is_true(found[m.send_note .. " - Write/Send note to Anki"] ~= nil)
			assert.is_true(found[m.attach_media .. " - Attach media (image/audio/video) [field buffers only]"] ~= nil)
		end)

		it("does not reference a 'kill_note' mapping key for editor context", function()
			assert.is_nil(config.options.mappings.editor.kill_note)
		end)
	end)

	describe("show_help for templates", function()
		it("does not error", function()
			local _, err = get_help_lines("templates")
			assert.is_nil(err)
		end)

		it("returns help lines referencing template mappings", function()
			local lines, err = get_help_lines("templates")
			assert.is_nil(err)
			assert.is_table(lines)
			assert.is_true(#lines > 0)

			local found = {}
			for _, line in ipairs(lines) do
				found[line] = true
			end
			local m = config.options.mappings.template
			assert.is_true(found[m.save_template .. " - Save template changes to Anki"] ~= nil)
			assert.is_true(found[m.pull_template .. " - Pull latest template from Anki"] ~= nil)
			assert.is_true(found[m.switch_card .. " - Switch card (for multi-card models)"] ~= nil)
			assert.is_true(found[m.close_template .. " - Close the template editor"] ~= nil)
		end)
	end)

	describe("show_help for media_browser", function()
		it("does not error", function()
			local _, err = get_help_lines("media_browser")
			assert.is_nil(err)
		end)

		it("returns help lines referencing media browser keymaps", function()
			local lines, err = get_help_lines("media_browser")
			assert.is_nil(err)
			assert.is_table(lines)

			local found = {}
			for _, line in ipairs(lines) do
				found[line] = true
			end
			assert.is_true(found["g? - Show this help window"] ~= nil)
			assert.is_true(found["<Enter> - Insert selected media reference"] ~= nil)
			assert.is_true(found["q / <Esc> - Close the media browser"] ~= nil)
		end)
	end)

	describe("show_help with custom mappings", function()
		it("reflects overridden mapping keys in help text", function()
			config.setup({
				mappings = {
					deck = {
						show_help = "gh",
					},
				},
			})
			cleanup_help_buffers()
			local lines, err = get_help_lines("decks")
			assert.is_nil(err)
			local found = false
			for _, line in ipairs(lines) do
				if line:find("gh") and line:find("Show this help window") then
					found = true
				end
			end
			assert.is_true(found)
		end)
	end)

	describe("close_help", function()
		it("does not error when no help buffer exists", function()
			assert.has_no.errors(function()
				help.close_help()
			end)
		end)
	end)
end)
