local M = {}

M.counter = 0

M.selected_deck = vim.g.anki_default_deck

-- @type Note[]
M.notes = {}

return M
