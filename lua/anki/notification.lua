---
--- anki.notification
---
--- Provides a unified notification interface for the plugin, using nvim-notify if available,
--- or falling back to vim.notify. Supports info, warning, and error levels.
---
local M = {}

--- Sends a notification using nvim-notify if available, or falls back to vim.notify.
-- @param message string The message to display.
-- @param level number The log level (vim.log.levels).
-- @param opts table Options for the notification (e.g., title).
local function notify(message, level, opts)
	local ok, notif = pcall(require, "notify")
	if ok then
		notif(message, level, opts)
	else
		vim.notify("[" .. opts.title .. "] " .. message)
	end
end

--- Shows an info-level notification.
-- @param message string The message to display.
function M.info(message)
	if type(message) ~= "string" then
		error("[anki.nvim][notification] info: message must be a string")
	end
	notify(message, vim.log.levels.INFO, { title = "Anki" })
end

--- Shows a warning-level notification.
-- @param message string The message to display.
function M.warn(message)
	if type(message) ~= "string" then
		error("[anki.nvim][notification] warn: message must be a string")
	end
	notify(message, vim.log.levels.WARN, { title = "Anki" })
end

--- Shows an error-level notification.
-- @param message string The message to display.
function M.error(message)
	if type(message) ~= "string" then
		error("[anki.nvim][notification] error: message must be a string")
	end
	notify(message, vim.log.levels.ERROR, { title = "Anki" })
end

return M
