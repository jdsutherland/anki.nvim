local M = {}

--- @class EditorContext
--- @field bufnr integer
--- @field winid integer
--- @field tabid integer
M.EditorContext = {}
M.EditorContext.__index = M.EditorContext

--- Constructor for EditorContext class.
--- @param o { bufnr: integer, winid: integer, tabid: integer}
--- @return EditorContext
function M.EditorContext:new(o)
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

--- @class Field
--- @field editor_context EditorContext
--- @field name string
M.Field = {}
M.Field.__index = M.Field

--- Constructor for Field class.
--- @param o { editor_context: EditorContext, name: string } Table to initialize the object with.
--- @return Field
function M.Field:new(o)
	o = o or {}
	assert(o.editor_context, "Field requires an 'editor_context'")
	assert(o.name and type(o.name) == "string", "Field requires a 'name'")
	setmetatable(o, {
		__index = self,
		__tostring = function(tbl)
			return string.format("Field(name=%s, bufnr=%d)", tbl.name, tbl.bufnr)
		end,
	})
	return o
end

--- @class Note
--- @field id integer|nil
--- @field fields Field[]
--- @field tags EditorContext
--- @field deck_name string
--- @field model_name string
--- @field display_mode nil|"split"|"vsplit"|"tabpage"|"custom"
M.Note = {}
M.Note.__index = M.Note

--- Constructor for Note class.
--- @param o { id?: integer, fields: Field[], tags: EditorContext, deck_name: string, model_name: string, display_mode: nil|"split"|"vsplit"|"tabpage"|"custom"  }
--- @return Note
function M.Note:new(o)
	o = o or {}
	assert(o.deck_name, "Note requires a 'deck_name'")
	assert(type(o.deck_name) == "string", "'deck_name' must be a string")
	assert(o.model_name, "Note requires a 'model_name'")
	assert(type(o.model_name) == "string", "'model_name' must be a string")
	assert(o.fields, "Note requires a 'fields' table")
	assert(
		o.tags and getmetatable(o.tags) and getmetatable(o.tags).__index == M.EditorContext,
		"Note requires a 'tags' of type EditorContext"
	)
	assert(
		o.display_mode == nil
			or (
				o.display_mode
				and (
					o.display_mode == "split"
					or o.display_mode == "vsplit"
					or o.display_mode == "tabpage"
					or o.display_mode == "custom"
				)
			),
		"Note 'display_mode' must be nil or have a value of ['split', 'vsplit', 'tabpage', 'custom']"
	)
	setmetatable(o, {
		__index = self,
		__tostring = function(tbl)
			return string.format(
				"Note(id=%s, deck=%s, model=%s, fields=%d)",
				tostring(tbl.id),
				tbl.deck_name,
				tbl.model_name,
				#tbl.fields
			)
		end,
	})
	return o
end

--- Finds a field in the note by its name.
--- @param name string The name of the field to find.
--- @return integer|nil The index of the field if found, otherwise nil.
function M.Note:find_field_by_name(name)
	for index, field in ipairs(self.fields) do
		if field.name == name then
			return index
		end
	end
end

--- Reads the content of the note's fields and tags from their respective Neovim buffers.
--- @return { fields: table<string, string>, tags: string[] }
function M.Note:get_content_from_buffers()
	local content = {
		fields = {},
		tags = {},
	}

	-- Get content from tags buffer
	content.tags = vim.api.nvim_buf_get_lines(self.tags.bufnr, 0, -1, false)

	-- Get content from field buffers
	for _, field in ipairs(self.fields) do
		local lines = vim.api.nvim_buf_get_lines(field.editor_context.bufnr, 0, -1, false)
		content.fields[field.name] = table.concat(lines, "\n")
	end

	return content
end

return M
