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

--- Asynchronous safe call wrapper for ankiconnect functions.
--- Calls an async ankiconnect function and routes results to on_success or on_error callbacks.
--- Error handling covers: transport failures, AnkiConnect API errors, and pcall-level crashes.
---
--- Usage:
---   utils.async_safe_call(ankiconnect.deck_names, function(result, error)
---     if error then ... end
---     -- use result
---   end)
---
--- Or with arguments:
---   utils.async_safe_call(ankiconnect.find_notes, { query }, function(result, error)
---     if error then ... end
---     -- use result
---   end)
---
---@param fn function An async ankiconnect function that takes a callback as its last argument.
---@param args table|nil Arguments to pass to fn (before the callback). Nil if fn takes no args besides callback.
---@param on_result function Callback receiving (result, error). result is nil on error, error is nil on success.
function M.async_safe_call(fn, args, on_result)
	if type(fn) ~= "function" then
		error("[anki.nvim][utils] async_safe_call: fn must be a function")
	end
	if type(on_result) ~= "function" then
		error("[anki.nvim][utils] async_safe_call: on_result must be a function")
	end

	local ok, err = pcall(function()
		local callback = function(result, error)
			vim.schedule(function()
				if error then
					notification.error("[anki.nvim][utils] " .. tostring(error))
					on_result(nil, error)
				else
					on_result(result, nil)
				end
			end)
		end

		if args == nil then
			fn(callback)
		else
			if type(args) ~= "table" then
				error("[anki.nvim][utils] async_safe_call: args must be a table or nil")
			end
			local call_args = {}
			for _, arg in ipairs(args) do
				table.insert(call_args, arg)
			end
			table.insert(call_args, callback)
			fn(unpack(call_args))
		end
	end)

	if not ok then
		vim.schedule(function()
			notification.error("[anki.nvim][utils] " .. tostring(err))
			on_result(nil, err)
		end)
	end
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
