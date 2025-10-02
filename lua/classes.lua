local M = {}

--- @class Field
--- @field bufnr integer|nil
--- @field name string|nil
M.Field = {}
M.Field.__index = M.Field

--- Constructor for Field class.
--- @param o table? Optional table to initialize the object with.
--- @return Field
function M.Field:new(o)
	o = o or {
		bufnr = nil,
		name = nil,
	}
	setmetatable(o, self)
	return o
end

--- @class Note
--- @field id integer|nil
--- @field tabpage number|nil
--- @field fields Field[]
--- @field tags table|nil
--- @field deck_name string|nil
--- @field model_name string|nil
M.Note = {}
M.Note.__index = M.Note

--- Constructor for Note class.
--- @param o table? Optional table to initialize the object with.
--- @return Note
function M.Note:new(o)
	o = o
		or {
			id = nil,
			tabpage = nil,
			fields = {},
			tag = {
				bufnr = nil,
			},
			deck_name = nil,
			model_name = nil,
		}
	setmetatable(o, self)
	return o
end

function M.Note:find_field_by_name(name)
	for index, field in ipairs(self.fields) do
		if field.name == name then
			return index
		end
	end
end

return M
