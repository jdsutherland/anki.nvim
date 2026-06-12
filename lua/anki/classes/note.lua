local EditorContext = require("anki.classes.editor_context")

local M = {}

M.__index = M

-- Type definition for EmmyLua
--- @class Note
--- @field fields Field[]
--- @field tags EditorContext
--- @field deck_name string
--- @field model_name string
--- @field id integer
--- @field media table|nil Inline media attachments for addNote (picture/audio/video arrays).
--- @field tabid integer|nil Tabpage ID of the note editor.
M.Note = M

--- Creates a new Note class instance.
-- @param o table Table with id (optional), fields (Field[]), tags (EditorContext), deck_name (string), model_name (string).
-- @return Note The new Note instance.
function M:new(o)
	o = o or {}
	assert(o.deck_name, "Note requires a 'deck_name'")
	assert(type(o.deck_name) == "string", "'deck_name' must be a string")
	assert(o.model_name, "Note requires a 'model_name'")
	assert(type(o.model_name) == "string", "'model_name' must be a string")
	assert(o.fields, "Note requires a 'fields' table")
	-- Convert plain table to EditorContext if needed for tags
	if o.tags and (not getmetatable(o.tags) or getmetatable(o.tags).__index ~= EditorContext) then
		o.tags = EditorContext:new(o.tags)
	end
	o.media = o.media or { picture = {}, audio = {}, video = {} }
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
-- @param name string The name of the field to find.
-- @return integer|nil The index of the field if found, otherwise nil.
function M:find_field_by_name(name)
	for index, field in ipairs(self.fields) do
		if field.name == name then
			return index
		end
	end
end

--- Reads the content of the note's fields and tags from their respective Neovim buffers.
-- @return table Table with fields (name to value) and tags (string array).
function M:get_content_from_buffers()
	local content = {
		fields = {},
		tags = {},
	}

	content.tags = vim.api.nvim_buf_get_lines(self.tags.bufnr, 0, -1, false)

	for _, field in ipairs(self.fields) do
		local lines = vim.api.nvim_buf_get_lines(field.editor_context.bufnr, 0, -1, false)
		content.fields[field.name] = table.concat(lines, "\n")
	end

	return content
end

--- Adds an inline media attachment to the note for use with addNote.
--- @param media_type string One of "picture", "audio", or "video".
--- @param entry table A media entry table. For pictures: { url/string/path, filename, fields }.
---   For audio/video: { url/string/path, filename, fields }.
function M:add_media(media_type, entry)
	if media_type ~= "picture" and media_type ~= "audio" and media_type ~= "video" then
		error("[anki.nvim][note] add_media: media_type must be 'picture', 'audio', or 'video'")
	end
	if type(entry) ~= "table" then
		error("[anki.nvim][note] add_media: entry must be a table")
	end
	table.insert(self.media[media_type], entry)
end

return M
