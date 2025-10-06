local notification = require("anki.notification")

local M = {}

function M.table_length(tbl)
	local length = 0
	for key, value in pairs(tbl) do
		length = length + 1
	end
	return length
end

function M.split(inputstr, sep)
	if sep == nil then
		sep = "%s" -- default separator is whitespace
	end
	local t = {}
	for str in string.gmatch(inputstr, "([^" .. sep .. "]+)") do
		table.insert(t, str)
	end
	return t
end

function M.safe_call(fn, ...)
	local response = fn(...)
	if response.error ~= vim.NIL then
		notification.error(vim.inspect(response.error))
		return nil
	end
	return response.result
end

return M
