local UI = require("anki.classes.ui")

---@class AnkiTemplateState
---@field model_name string Name of the model being edited.
---@field card_name string Name of the currently displayed card.
---@field cards table Mapping of card names to { Front, Back } template content.
---@field front_bufnr integer Buffer number for the Front template.
---@field back_bufnr integer Buffer number for the Back template.
---@field styling_bufnr integer Buffer number for the CSS styling.
---@field tabid integer Tabpage ID of the template editor.

---@class AnkiState
---@field counter number
---@field current_note Note | nil
---@field current_template table<integer, AnkiTemplateState> Per-tabpage template editor state.
---@field ui UI
local M = {
	counter = 0,
	current_note = nil,
	current_template = {},
	ui = UI:new({
		win_id = nil,
		deck_buf_id = nil,
		note_buf_id = nil,
		editor_win_id = nil,
		notes = {},
		current_filter = nil, -- Track: nil=all, deck_name=filtered
	}),
}

return M
