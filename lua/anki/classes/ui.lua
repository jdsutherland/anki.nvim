local M = {}

M.__index = M

-- Type definition for EmmyLua
--- @class UI
--- @field win_id integer | nil
--- @field deck_buf_id integer | nil
--- @field note_buf_id integer | nil
--- @field notes Note[]
--- @field cards table[]
--- @field decks string[]
--- @field current_filter string | nil
--- @field view_mode string "notes" | "cards"
M.UI = M

--- Creates a new UI class instance.
-- @param o table Table of UI properties.
-- @return UI The new UI instance.
function M:new(o)
	o = o or {}
	o.notes = o.notes or {}
	o.cards = o.cards or {}
	o.decks = o.decks or {}
	o.view_mode = o.view_mode or "notes"
	setmetatable(o, {
		__index = self,
		__tostring = function(tbl)
			return string.format(
				"UI(win_id=%s, deck_buf_id=%s, note_buf_id=%s, notes=%d, cards=%d, decks=%d, current_filter=%s, view_mode=%s)",
				tostring(tbl.win_id),
				tostring(tbl.deck_buf_id),
				tostring(tbl.note_buf_id),
				#tbl.notes,
				#tbl.cards,
				#tbl.decks,
				tostring(tbl.current_filter),
				tostring(tbl.view_mode)
			)
		end,
	})
	return o
end

return M
