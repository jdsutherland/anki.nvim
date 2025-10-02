-- Setup variables
vim.g.anki_url = vim.g.anki_url or "http://localhost:8765"
vim.g.anki_timeout = vim.g.anki_timeout or 500
vim.g.anki_prefix = vim.g.anki_prefix or "<leader>a"
vim.g.anki_default_mappings = vim.g.anki_default_mappings or true
vim.g.anki_quickdeck = vim.g.anki_quickdeck or "TestDeck"
vim.g.anki_gui_browse_enabled = vim.g.anki_gui_browse_enabled or true
vim.g.anki_custom_display = vim.g.anki_custom_display or nil
vim.g.anki_custom_delete = vim.g.anki_custom_delete or nil
vim.g.anki_after_edit_buffer_hook = vim.g.anki_after_edit_buffer_hook or nil

-- Setup mappings
if vim.g.anki_default_mappings then
	require("which-key").add({
		mode = { "n" },
		nowait = true,
		remap = false,

		{ vim.g.anki_prefix .. "a", group = "[ANKI] Deck Add Note" },
		{ vim.g.anki_prefix .. "ab", "<cmd>AnkiDeckAddNote<CR>", desc = "Deck Add Note" },
		{ vim.g.anki_prefix .. "as", "<cmd>AnkiDeckAddNoteSplit<CR>", desc = "Deck Add Note Split" },
		{ vim.g.anki_prefix .. "av", "<cmd>AnkiDeckAddNoteVsplit<CR>", desc = "Deck Add Note Vsplit" },
		{ vim.g.anki_prefix .. "at", "<cmd>AnkiDeckAddNoteTabpage<CR>", desc = "Deck Add Note Tabpage" },
		{ vim.g.anki_prefix .. "ac", "<cmd>AnkiDeckAddNoteCustom<CR>", desc = "Deck Add Note Custom" },

		{ vim.g.anki_prefix .. "e", group = "[ANKI] Deck Edit Note" },
		{ vim.g.anki_prefix .. "eb", "<cmd>AnkiDeckEditNote<CR>", desc = "Deck Edit Note" },
		{ vim.g.anki_prefix .. "es", "<cmd>AnkiDeckEditNoteSplit<CR>", desc = "Deck Edit Note Split" },
		{ vim.g.anki_prefix .. "ev", "<cmd>AnkiDeckEditNoteVsplit<CR>", desc = "Deck Edit Note Vsplit" },
		{ vim.g.anki_prefix .. "et", "<cmd>AnkiDeckEditNoteTabpage<CR>", desc = "Deck Edit Note Tabpage" },
		{ vim.g.anki_prefix .. "ec", "<cmd>AnkiDeckEditNoteCustom<CR>", desc = "Deck Edit Note Custom" },

		{ vim.g.anki_prefix .. "A", group = "[ANKI] Add Note" },
		{ vim.g.anki_prefix .. "Ab", "<cmd>AnkiAddNote<CR>", desc = "Add Note" },
		{ vim.g.anki_prefix .. "As", "<cmd>AnkiAddNoteSplit<CR>", desc = "Add Note Split" },
		{ vim.g.anki_prefix .. "Av", "<cmd>AnkiAddNoteVsplit<CR>", desc = "Add Note Vsplit" },
		{ vim.g.anki_prefix .. "At", "<cmd>AnkiAddNoteTabpage<CR>", desc = "Add Note Tabpage" },
		{ vim.g.anki_prefix .. "Ac", "<cmd>AnkiAddNoteCustom<CR>", desc = "Add Note Custom" },

		{ vim.g.anki_prefix .. "E", group = "[ANKI] Edit Note" },
		{ vim.g.anki_prefix .. "Eb", "<cmd>AnkiEditNote<CR>", desc = "Edit Note" },
		{ vim.g.anki_prefix .. "Es", "<cmd>AnkiEditNoteSplit<CR>", desc = "Edit Note Split" },
		{ vim.g.anki_prefix .. "Ev", "<cmd>AnkiEditNoteVsplit<CR>", desc = "Edit Note Vsplit" },
		{ vim.g.anki_prefix .. "Et", "<cmd>AnkiEditNoteTabpage<CR>", desc = "Edit Note Tabpage" },
		{ vim.g.anki_prefix .. "Ec", "<cmd>AnkiEditNoteCustom<CR>", desc = "Edit Note Custom" },

		{ vim.g.anki_prefix .. "c", "<cmd>AnkiDeckCreate<CR>", desc = "Deck Create" },
		{ vim.g.anki_prefix .. "d", "<cmd>AnkiDeckDeleteNote<CR>", desc = "Deck Delete Note" },
		{ vim.g.anki_prefix .. "D", "<cmd>AnkiDeleteNote<CR>", desc = "Delete Note" },

		{ vim.g.anki_prefix .. "f", "<cmd>AnkiSelectDeck<CR>", desc = "Select Deck" },
		{ vim.g.anki_prefix .. "i", "<cmd>AnkiInfos<CR>", desc = "Infos" },

		{ vim.g.anki_prefix .. "k", "<cmd>AnkiCurrentKillNote<CR>", desc = "Kill Current Note" },
		{ vim.g.anki_prefix .. "w", "<cmd>AnkiCurrentSendNote<CR>", desc = "Send Current Note" },
		{ vim.g.anki_prefix .. "p", "<cmd>AnkiCurrentPullNote<CR>", desc = "Pull Current Note" },
		{ vim.g.anki_prefix .. "r", "<cmd>AnkiCurrentDeleteNote<CR>", desc = "Delete Current Note" },

		{ vim.g.anki_prefix .. "b", group = "[ANKI] GUI Browse" },
		{ vim.g.anki_prefix .. "bf", "<cmd>AnkiGUIBrowseDeck<CR>", desc = "Browse To QuickDeck In Gui" },
		{ vim.g.anki_prefix .. "bd", "<cmd>AnkiCurrentGUIBrowseDeck<CR>", desc = "Browse To Current Note Deck In Gui" },
		{ vim.g.anki_prefix .. "bn", "<cmd>AnkiCurrentGUIBrowseNote<CR>", desc = "Browse To Current Note In Gui" },

		{ vim.g.anki_prefix, group = "[ANKI]" },
	})
end

-- Setup commands

vim.api.nvim_create_user_command("AnkiDeckAddNote", function()
	require("anki.api").add_note_to_quick_deck()
end, {
	desc = "[Anki] Create A Note On The QuickDeck In The Current Buffer",
	nargs = 0,
})
vim.api.nvim_create_user_command("AnkiDeckAddNoteSplit", function()
	require("anki.api").add_note_to_quick_deck({ display = "split" })
end, {
	desc = "[Anki] Create A Note On The QuickDeck In A New Split",
	nargs = 0,
})
vim.api.nvim_create_user_command("AnkiDeckAddNoteVsplit", function()
	require("anki.api").add_note_to_quick_deck({ display = "vsplit" })
end, {
	desc = "[Anki] Create A Note On The QuickDeck In A New Vsplit",
	nargs = 0,
})
vim.api.nvim_create_user_command("AnkiDeckAddNoteTabpage", function()
	require("anki.api").add_note_to_quick_deck({ display = "tabpage" })
end, {
	desc = "[Anki] Create A Note On The QuickDeck In A New Tabpage",
	nargs = 0,
})

vim.api.nvim_create_user_command("AnkiDeckAddNoteCustom", function()
	require("anki.api").add_note_to_quick_deck({ display = "custom" })
end, {
	desc = "[Anki] Create A Note On The QuickDeck Using The Custom Method",
	nargs = 0,
})

vim.api.nvim_create_user_command("AnkiDeckEditNote", function()
	require("anki.api").edit_note_from_quick_deck()
end, {
	desc = "[Anki] Edit A Note On The QuickDeck In The Current Window",
	nargs = 0,
})
vim.api.nvim_create_user_command("AnkiDeckEditNoteSplit", function()
	require("anki.api").edit_note_from_quick_deck({ display = "split" })
end, {
	desc = "[Anki] Edit A Note On The QuickDeck In A New Split",
	nargs = 0,
})
vim.api.nvim_create_user_command("AnkiDeckEditNoteVsplit", function()
	require("anki.api").edit_note_from_quick_deck({ display = "vsplit" })
end, {
	desc = "[Anki] Edit A Note On The QuickDeck In A New Vsplit",
	nargs = 0,
})
vim.api.nvim_create_user_command("AnkiDeckEditNoteTabpage", function()
	require("anki.api").edit_note_from_quick_deck({ display = "tabpage" })
end, {
	desc = "[Anki] Edit A Note On The QuickDeck In A New Tabpage",
	nargs = 0,
})
vim.api.nvim_create_user_command("AnkiDeckEditNoteCustom", function()
	require("anki.api").edit_note_from_quick_deck({ display = "custom" })
end, {
	desc = "[Anki] Edit A Note On The QuickDeck Using The Custom Method",
	nargs = 0,
})

vim.api.nvim_create_user_command("AnkiDeckCreate", function()
	require("anki.api").add_deck()
end, {
	desc = "[Anki] Create a deck",
	nargs = 0,
})

vim.api.nvim_create_user_command("AnkiDeckDeleteNote", function()
	require("anki.api").pick_note_to_delete_from_quick_deck()
end, {
	desc = "[Anki] Delete A Note On The QuickDeck",
	nargs = 0,
})

vim.api.nvim_create_user_command("AnkiAddNote", function()
	require("anki.api").add_note()
end, {
	desc = "[Anki] Create A Note In The Current Window",
	nargs = 0,
})
vim.api.nvim_create_user_command("AnkiAddNoteSplit", function()
	require("anki.api").add_note({ display = "split" })
end, {
	desc = "[Anki] Create A Note In A New Split",
	nargs = 0,
})
vim.api.nvim_create_user_command("AnkiAddNoteVsplit", function()
	require("anki.api").add_note({ display = "vsplit" })
end, {
	desc = "[Anki] Create A Note In A New Vsplit",
	nargs = 0,
})
vim.api.nvim_create_user_command("AnkiAddNoteTabpage", function()
	require("anki.api").add_note({ display = "tabpage" })
end, {
	desc = "[Anki] Create A Note In A New Tabapge",
	nargs = 0,
})
vim.api.nvim_create_user_command("AnkiAddNoteCustom", function()
	require("anki.api").add_note({ display = "custom" })
end, {
	desc = "[Anki] Create A Note Using The Custom Method",
	nargs = 0,
})
vim.api.nvim_create_user_command("AnkiEditNote", function()
	require("anki.api").edit_note()
end, {
	desc = "[Anki] Edit A Note In The Current Window",
	nargs = 0,
})
vim.api.nvim_create_user_command("AnkiEditNoteSplit", function()
	require("anki.api").edit_note({ display = "split" })
end, {
	desc = "[Anki] Edit A Note In A New Split",
	nargs = 0,
})
vim.api.nvim_create_user_command("AnkiEditNoteVsplit", function()
	require("anki.api").edit_note({ display = "vsplit" })
end, {
	desc = "[Anki] Edit A Note In A New Vsplit",
	nargs = 0,
})
vim.api.nvim_create_user_command("AnkiEditNoteTabpage", function()
	require("anki.api").edit_note({ display = "tabpage" })
end, {
	desc = "[Anki] Edit A Note In A New Tabapge",
	nargs = 0,
})
vim.api.nvim_create_user_command("AnkiEditNoteCustom", function()
	require("anki.api").edit_note({ display = "custom" })
end, {
	desc = "[Anki] Edit A Note Using The Custom Method",
	nargs = 0,
})
vim.api.nvim_create_user_command("AnkiDeleteNote", function()
	require("anki.api").pick_delete_note()
end, {
	desc = "[Anki] Delete A Note",
	nargs = 0,
})
vim.api.nvim_create_user_command("AnkiSelectDeck", function()
	require("anki.api").select_state_deck()
end, {
	desc = "[Anki] Select The Deck",
	nargs = 0,
})

vim.api.nvim_create_user_command("AnkiInfos", function()
	require("anki.api").infos()
end, {
	desc = "[Anki] Infos",
})

vim.api.nvim_create_user_command("AnkiCurrentKillNote", function()
	require("anki.api").kill_note(vim.api.nvim_get_current_buf())
end, {
	desc = "[Anki] Kill The Current Buffer Note",
	nargs = 0,
})
vim.api.nvim_create_user_command("AnkiCurrentSendNote", function()
	require("anki.api").send_note(vim.api.nvim_get_current_buf())
end, {
	desc = "[Anki] Send The Note Of The Current Buffer To Anki",
	nargs = 0,
})
vim.api.nvim_create_user_command("AnkiCurrentPullNote", function()
	require("anki.api").pull_note(vim.api.nvim_get_current_buf())
end, {
	desc = "[Anki] Pull The Current Buffer Note From Anki",
})
vim.api.nvim_create_user_command("AnkiCurrentDeleteNote", function()
	require("anki.api").delete_note(vim.api.nvim_get_current_buf())
end, {
	desc = "[Anki] Delete The Current Buffer Note From Anki",
})

vim.api.nvim_create_user_command("AnkiGUIBrowseDeck", function()
	require("anki.api").gui_deck()
end, {
	desc = "[Anki] GUI Browse QuickDeck",
})

vim.api.nvim_create_user_command("AnkiCurrentGUIBrowseDeck", function()
	require("anki.api").gui_deck_current(vim.api.nvim_get_current_buf())
end, {
	desc = "[Anki] GUI Browse Current Note Deck",
})

vim.api.nvim_create_user_command("AnkiCurrentGUIBrowseNote", function()
	require("anki.api").gui_note(vim.api.nvim_get_current_buf())
end, {
	desc = "[Anki] GUI Browse Current Note",
})
