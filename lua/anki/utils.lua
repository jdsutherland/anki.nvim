local notification = require("anki.notification")

---
--- anki.utils
---
--- Utility functions for table operations, string splitting, and safe function calls with error handling.
---
local M = {}

--- Splits a string by the given separator.
-- @param inputstr string The string to split.
-- @param sep string|nil The separator (defaults to whitespace).
-- @return table List of split substrings.
function M.split(inputstr, sep)
	if type(inputstr) ~= "string" then
		error("[anki.nvim][utils] split: inputstr must be a string")
	end
	if sep ~= nil and type(sep) ~= "string" then
		error("[anki.nvim][utils] split: sep must be a string or nil")
	end
	if sep == nil then
		sep = "%s" -- default separator is whitespace
	end
	local t = {}
	for str in string.gmatch(inputstr, "([^" .. sep .. "]+)") do
		table.insert(t, str)
	end
	return t
end

--- Safely calls a function and handles errors, returning the result or nil.
-- @param fn function The function to call.
-- @param ... any Arguments to pass to the function.
-- @return any The result of the function, or nil on error.
function M.safe_call(fn, ...)
	if type(fn) ~= "function" then
		error("[anki.nvim][utils] safe_call: fn must be a function")
	end
	local ok, result = pcall(fn, ...)
	if not ok then
		notification.error("[anki.nvim][utils] " .. tostring(result))
		return nil
	end

	if result.error ~= nil and result.error ~= vim.NIL then
		notification.error("[anki.nvim][utils] " .. vim.inspect(result.error))
		return nil
	end

	return result.result
end

--- Gets the visual or cursor line range for the current selection.
--- In visual mode, returns the start and end lines of the selection.
--- In normal mode, returns the current line for both start and end.
---@return number start_line The starting line number (1-based).
---@return number end_line The ending line number (1-based).
function M.get_visual_line_range()
	local mode = vim.fn.mode()
	if mode == "v" or mode == "V" or mode == "\22" then
		local start_line = vim.fn.line("v")
		local end_line = vim.fn.line(".")
		if start_line > end_line then
			start_line, end_line = end_line, start_line
		end
		return start_line, end_line
	end
	local line = vim.api.nvim_win_get_cursor(0)[1]
	return line, line
end

--- Escapes special characters in a string for use in Anki search queries.
---@param str string The string to escape.
---@return string The escaped string.
function M.escape_search_query(str)
	return str:gsub([[\]], [[\\]]):gsub('"', '\\"')
end

return M
