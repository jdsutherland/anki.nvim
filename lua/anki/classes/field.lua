local EditorContext = require("anki.classes.editor_context")

local M = {}

M.__index = M

-- Type definition for EmmyLua
--- @class Field
--- @field editor_context EditorContext
--- @field name string
M.Field = M

--- Creates a new Field class instance.
-- @param o table Table with editor_context (EditorContext) and name (string).
-- @return Field The new Field instance.
function M:new(o)
	o = o or {}
	assert(o.editor_context, "Field requires an 'editor_context'")
	assert(o.name and type(o.name) == "string", "Field requires a 'name'")
	-- Convert plain table to EditorContext if needed
	if not getmetatable(o.editor_context) or getmetatable(o.editor_context).__index ~= EditorContext then
		o.editor_context = EditorContext:new(o.editor_context)
	end
	setmetatable(o, {
		__index = self,
		__tostring = function(tbl)
			return string.format("Field(name=%s, bufnr=%d)", tbl.name, tbl.editor_context.bufnr)
		end,
	})
	return o
end

return M
