local M = {}

M.__index = M

-- Type definition for EmmyLua
--- @class EditorContext
--- @field bufnr integer
--- @field winid integer
--- @field tabid integer
M.EditorContext = M

--- Creates a new EditorContext class instance.
-- @param o table Table with bufnr (integer), winid (integer), tabid (integer).
-- @return EditorContext The new EditorContext instance.
function M:new(o)
	o = o or {}
	assert(o.bufnr and type(o.bufnr) == "number", "EditorContext requires a 'bufnr'")
	assert(o.winid and type(o.winid) == "number", "EditorContext requires a 'winid'")
	assert(o.tabid and type(o.tabid) == "number", "EditorContext requires a 'tabid'")

	setmetatable(o, {
		__index = self,
		__tostring = function(tbl)
			return string.format("EditorContext(bufnr=%d, winid=%d, tabid=%d)", tbl.bufnr, tbl.winid, tbl.tabid)
		end,
	})
	return o
end

return M
