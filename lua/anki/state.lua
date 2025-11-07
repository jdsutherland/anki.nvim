local UI = require("anki.classes.ui")

---@class AnkiState
---@field counter number
---@field current_note Note | nil
---@field ui UI
local M = {
	counter = 0,
	current_note = nil,
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
