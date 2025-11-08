local M = {}

M.__index = M

-- Type definition for EmmyLua
--- @class UI
--- @field win_id integer | nil
--- @field deck_buf_id integer | nil
--- @field note_buf_id integer | nil
--- @field editor_win_id integer | nil
--- @field notes Note[]
--- @field decks string[]
--- @field current_filter string | nil
M.UI = M

--- Creates a new UI class instance.
-- @param o table Table of UI properties (win_id, deck_buf_id, note_buf_id, editor_win_id, notes, current_filter).
-- @return UI The new UI instance.
function M:new(o)
	o = o or {}
	setmetatable(o, {
		__index = self,
		__tostring = function(tbl)
			return string.format(
				"UI(win_id=%s, deck_buf_id=%s, note_buf_id=%s, editor_win_id=%s, notes=%d, decks=%d, current_filter=%s)",
				tostring(tbl.win_id),
				tostring(tbl.deck_buf_id),
				tostring(tbl.note_buf_id),
				tostring(tbl.editor_win_id),
				#tbl.notes,
				#tbl.decks,
				tostring(tbl.current_filter)
			)
		end,
	})
	return o
end

return M
