local M = {}

local function notify(message, level, opts)
	local ok, notif = pcall(require, "notify")
	if ok then
		notif(message, level, opts)
	else
		vim.notify("[" .. opts.title .. "] " .. message)
	end
end

function M.info(message)
	notify(message, vim.log.levels.INFO, { title = "Anki" })
end

function M.warn(message)
	notify(message, vim.log.levels.WARN, { title = "Anki" })
end

function M.error(message)
	notify(message, vim.log.levels.ERROR, { title = "Anki" })
end

return M

