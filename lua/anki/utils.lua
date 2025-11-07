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

	if result.error ~= vim.NIL then
		notification.error("[anki.nvim][utils] " .. vim.inspect(result.error))
		return nil
	end

	return result.result
end

return M
