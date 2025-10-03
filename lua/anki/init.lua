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
	if pcall(require, "which-key") then
		require("which-key").add({
			mode = { "n" },
			nowait = true,
			remap = false,
			{ vim.g.anki_prefix .. "a", group = "[ANKI] QuickDeck Add Note" },
			{ vim.g.anki_prefix .. "ab",function() require("anki.api").add_note_to_quick_deck() end, desc = "QuickDeck Add Note" },
			{ vim.g.anki_prefix .. "as",function() require("anki.api").add_note_to_quick_deck({ display = "split" }) end, desc = "QuickDeck Add Note Split" },
			{ vim.g.anki_prefix .. "av",function() require("anki.api").add_note_to_quick_deck({ display = "vsplit" }) end, desc = "QuickDeck Add Note Vsplit" },
			{ vim.g.anki_prefix .. "at",function() require("anki.api").add_note_to_quick_deck({ display = "tabpage" }) end, desc = "QuickDeck Add Note Tabpage" },
			{ vim.g.anki_prefix .. "ac",function() require("anki.api").add_note_to_quick_deck({ display = "custom" }) end, desc = "QuickDeck Add Note Custom" },

			{ vim.g.anki_prefix .. "e", group = "[ANKI] QuickDeck Edit Note" },
			{ vim.g.anki_prefix .. "eb",function() require("anki.api").edit_note_from_quick_deck() end, desc = "QuickDeck Edit Note" },
			{ vim.g.anki_prefix .. "es",function() require("anki.api").edit_note_from_quick_deck({ display = "split" }) end, desc = "QuickDeck Edit Note Split" },
			{ vim.g.anki_prefix .. "ev",function() require("anki.api").edit_note_from_quick_deck({ display = "vsplit" }) end, desc = "QuickDeck Edit Note Vsplit" },
			{ vim.g.anki_prefix .. "et",function() require("anki.api").edit_note_from_quick_deck({ display = "tabpage" }) end, desc = "QuickDeck Edit Note Tabpage" },
			{ vim.g.anki_prefix .. "ec",function() require("anki.api").edit_note_from_quick_deck({ display = "custom" }) end, desc = "QuickDeck Edit Note Custom" },

			{ vim.g.anki_prefix .. "A", group = "[ANKI] Add Note" },
			{ vim.g.anki_prefix .. "Ab",function() require("anki.api").add_note() end, desc = "Add Note" },
			{ vim.g.anki_prefix .. "As",function() require("anki.api").add_note({ display = "split" }) end, desc = "Add Note Split" },
			{ vim.g.anki_prefix .. "Av",function() require("anki.api").add_note({ display = "vsplit" }) end, desc = "Add Note Vsplit" },
			{ vim.g.anki_prefix .. "At",function() require("anki.api").add_note({ display = "tabpage" }) end, desc = "Add Note Tabpage" },
			{ vim.g.anki_prefix .. "Ac",function() require("anki.api").add_note({ display = "custom" }) end, desc = "Add Note Custom" },

			{ vim.g.anki_prefix .. "E", group = "[ANKI] Edit Note" },
			{ vim.g.anki_prefix .. "Eb",function() require("anki.api").edit_note() end, desc = "Edit Note" },
			{ vim.g.anki_prefix .. "Es",function() require("anki.api").edit_note({ display = "split" }) end, desc = "Edit Note Split" },
			{ vim.g.anki_prefix .. "Ev",function() require("anki.api").edit_note({ display = "vsplit" }) end, desc = "Edit Note Vsplit" },
			{ vim.g.anki_prefix .. "Et",function() require("anki.api").edit_note({ display = "tabpage" }) end, desc = "Edit Note Tabpage" },
			{ vim.g.anki_prefix .. "Ec",function() require("anki.api").edit_note({ display = "custom" }) end, desc = "Edit Note Custom" },

			{ vim.g.anki_prefix .. "c",function() require("anki.api").add_deck() end, desc = "QuickDeck Create" },
			{ vim.g.anki_prefix .. "d",function() require("anki.api").pick_note_to_delete_from_quick_deck() end, desc = "QuickDeck Delete Note" },
			{ vim.g.anki_prefix .. "D",function() require("anki.api").pick_delete_note() end, desc = "Delete Note" },

			{ vim.g.anki_prefix .. "f",function() require("anki.api").select_state_quickdeck() end, desc = "Select QuickDeck" },
			{ vim.g.anki_prefix .. "i",function() require("anki.api").infos() end, desc = "Infos" },

			{ vim.g.anki_prefix .. "k",function() require("anki.api").kill_note(vim.api.nvim_get_current_buf()) end, desc = "Kill Current Note" },
			{ vim.g.anki_prefix .. "w",function() require("anki.api").send_note(vim.api.nvim_get_current_buf()) end, desc = "Send Current Note" },
			{ vim.g.anki_prefix .. "p",function() require("anki.api").pull_note(vim.api.nvim_get_current_buf()) end, desc = "Pull Current Note" },
			{ vim.g.anki_prefix .. "r",function() require("anki.api").delete_note(vim.api.nvim_get_current_buf()) end, desc = "Delete Current Note" },

			{ vim.g.anki_prefix .. "b", group = "[ANKI] GUI Browse" },
			{ vim.g.anki_prefix .. "bf",function() require("anki.api").gui_deck() end, desc = "GUI Browse To QuickDeck" },
			{ vim.g.anki_prefix .. "bd",function() require("anki.api").gui_deck_current(vim.api.nvim_get_current_buf()) end,desc = "GUI Browse To Current Note Deck"},
			{ vim.g.anki_prefix .. "bn",function() require("anki.api").gui_note(vim.api.nvim_get_current_buf()) end, desc = "GUI Browse To Current Note" },
			{ vim.g.anki_prefix, group = "[ANKI]" },
		})
  else
			vim.keymap.set({"n"}, vim.g.anki_prefix .. "ab",function() require("anki.api").add_note_to_quick_deck() end, {desc = "QuickDeck Add Note" })
			vim.keymap.set({"n"}, vim.g.anki_prefix .. "as",function() require("anki.api").add_note_to_quick_deck({ display = "split" }) end, {desc = "QuickDeck Add Note Split" })
			vim.keymap.set({"n"}, vim.g.anki_prefix .. "av",function() require("anki.api").add_note_to_quick_deck({ display = "vsplit" }) end, {desc = "QuickDeck Add Note Vsplit" })
			vim.keymap.set({"n"}, vim.g.anki_prefix .. "at",function() require("anki.api").add_note_to_quick_deck({ display = "tabpage" }) end, {desc = "QuickDeck Add Note Tabpage" })
			vim.keymap.set({"n"}, vim.g.anki_prefix .. "ac",function() require("anki.api").add_note_to_quick_deck({ display = "custom" }) end, {desc = "QuickDeck Add Note Custom" })

			vim.keymap.set({"n"}, vim.g.anki_prefix .. "eb",function() require("anki.api").edit_note_from_quick_deck() end, {desc = "QuickDeck Edit Note" })
			vim.keymap.set({"n"}, vim.g.anki_prefix .. "es",function() require("anki.api").edit_note_from_quick_deck({ display = "split" }) end, {desc = "QuickDeck Edit Note Split" })
			vim.keymap.set({"n"}, vim.g.anki_prefix .. "ev",function() require("anki.api").edit_note_from_quick_deck({ display = "vsplit" }) end, {desc = "QuickDeck Edit Note Vsplit" })
			vim.keymap.set({"n"}, vim.g.anki_prefix .. "et",function() require("anki.api").edit_note_from_quick_deck({ display = "tabpage" }) end, {desc = "QuickDeck Edit Note Tabpage" })
			vim.keymap.set({"n"}, vim.g.anki_prefix .. "ec",function() require("anki.api").edit_note_from_quick_deck({ display = "custom" }) end, {desc = "QuickDeck Edit Note Custom" })

			vim.keymap.set({"n"}, vim.g.anki_prefix .. "Ab",function() require("anki.api").add_note() end, {desc = "Add Note" })
			vim.keymap.set({"n"}, vim.g.anki_prefix .. "As",function() require("anki.api").add_note({ display = "split" }) end, {desc = "Add Note Split" })
			vim.keymap.set({"n"}, vim.g.anki_prefix .. "Av",function() require("anki.api").add_note({ display = "vsplit" }) end, {desc = "Add Note Vsplit" })
			vim.keymap.set({"n"}, vim.g.anki_prefix .. "At",function() require("anki.api").add_note({ display = "tabpage" }) end, {desc = "Add Note Tabpage" })
			vim.keymap.set({"n"}, vim.g.anki_prefix .. "Ac",function() require("anki.api").add_note({ display = "custom" }) end, {desc = "Add Note Custom" })

			vim.keymap.set({"n"}, vim.g.anki_prefix .. "Eb",function() require("anki.api").edit_note() end, {desc = "Edit Note" })
			vim.keymap.set({"n"}, vim.g.anki_prefix .. "Es",function() require("anki.api").edit_note({ display = "split" }) end, {desc = "Edit Note Split" })
			vim.keymap.set({"n"}, vim.g.anki_prefix .. "Ev",function() require("anki.api").edit_note({ display = "vsplit" }) end, {desc = "Edit Note Vsplit" })
			vim.keymap.set({"n"}, vim.g.anki_prefix .. "Et",function() require("anki.api").edit_note({ display = "tabpage" }) end, {desc = "Edit Note Tabpage" })
			vim.keymap.set({"n"}, vim.g.anki_prefix .. "Ec",function() require("anki.api").edit_note({ display = "custom" }) end, {desc = "Edit Note Custom" })

			vim.keymap.set({"n"}, vim.g.anki_prefix .. "c",function() require("anki.api").add_deck() end, {desc = "QuickDeck Create" })
			vim.keymap.set({"n"}, vim.g.anki_prefix .. "d",function() require("anki.api").pick_note_to_delete_from_quick_deck() end, {desc = "QuickDeck Delete Note" })
			vim.keymap.set({"n"}, vim.g.anki_prefix .. "D",function() require("anki.api").pick_delete_note() end, {desc = "Delete Note" })

			vim.keymap.set({"n"}, vim.g.anki_prefix .. "f",function() require("anki.api").select_state_quickdeck() end, {desc = "Select QuickDeck" })
			vim.keymap.set({"n"}, vim.g.anki_prefix .. "i",function() require("anki.api").infos() end, {desc = "Infos" })

			vim.keymap.set({"n"}, vim.g.anki_prefix .. "k",function() require("anki.api").kill_note(vim.api.nvim_get_current_buf()) end, {desc = "Kill Current Note" })
			vim.keymap.set({"n"}, vim.g.anki_prefix .. "w",function() require("anki.api").send_note(vim.api.nvim_get_current_buf()) end, {desc = "Send Current Note" })
			vim.keymap.set({"n"}, vim.g.anki_prefix .. "p",function() require("anki.api").pull_note(vim.api.nvim_get_current_buf()) end, {desc = "Pull Current Note" })
			vim.keymap.set({"n"}, vim.g.anki_prefix .. "r",function() require("anki.api").delete_note(vim.api.nvim_get_current_buf()) end, {desc = "Delete Current Note" })

			vim.keymap.set({"n"}, vim.g.anki_prefix .. "bf",function() require("anki.api").gui_deck() end, {desc = "GUI Browse To QuickDeck" })
			vim.keymap.set({"n"}, vim.g.anki_prefix .. "bd",function() require("anki.api").gui_deck_current(vim.api.nvim_get_current_buf()) end,{desc = "GUI Browse To Current Note Deck" })
			vim.keymap.set({"n"}, vim.g.anki_prefix .. "bn",function() require("anki.api").gui_note(vim.api.nvim_get_current_buf()) end, {desc = "GUI Browse To Current Note" })
	end
end

-- Setup commands

if vim.g.anki_create_user_commands then

  vim.api.nvim_create_user_command("AnkiQuickDeckAddNote", function() require("anki.api").add_note_to_quick_deck() end,
  { desc = "[Anki] Create A Note On The QuickDeck In The Current Buffer",
    nargs = 0,
  })
  vim.api.nvim_create_user_command("AnkiQuickDeckAddNoteSplit", function() require("anki.api").add_note_to_quick_deck({ display = "split" }) end,
  {
    desc = "[Anki] Create A Note On The QuickDeck In A New Split",
    nargs = 0,
  })
  vim.api.nvim_create_user_command("AnkiQuickDeckAddNoteVsplit", function() require("anki.api").add_note_to_quick_deck({ display = "vsplit" }) end,
  {
    desc = "[Anki] Create A Note On The QuickDeck In A New Vsplit",
    nargs = 0,
  })
  vim.api.nvim_create_user_command("AnkiQuickDeckAddNoteTabpage", function() require("anki.api").add_note_to_quick_deck({ display = "tabpage" }) end,
  {
    desc = "[Anki] Create A Note On The QuickDeck In A New Tabpage",
    nargs = 0,
  })

  vim.api.nvim_create_user_command("AnkiQuickDeckAddNoteCustom", function() require("anki.api").add_note_to_quick_deck({ display = "custom" }) end,
  {
    desc = "[Anki] Create A Note On The QuickDeck Using The Custom Method",
    nargs = 0,
  })

  vim.api.nvim_create_user_command("AnkiQuickDeckEditNote", function() require("anki.api").edit_note_from_quick_deck() end,
  {
    desc = "[Anki] Edit A Note On The QuickDeck In The Current Window",
    nargs = 0,
  })
  vim.api.nvim_create_user_command("AnkiQuickDeckEditNoteSplit", function() require("anki.api").edit_note_from_quick_deck({ display = "split" }) end,
  {
    desc = "[Anki] Edit A Note On The QuickDeck In A New Split",
    nargs = 0,
  })
  vim.api.nvim_create_user_command("AnkiQuickDeckEditNoteVsplit", function() require("anki.api").edit_note_from_quick_deck({ display = "vsplit" }) end,
  {
    desc = "[Anki] Edit A Note On The QuickDeck In A New Vsplit",
    nargs = 0,
  })
  vim.api.nvim_create_user_command("AnkiQuickDeckEditNoteTabpage", function() require("anki.api").edit_note_from_quick_deck({ display = "tabpage" }) end,
  {
    desc = "[Anki] Edit A Note On The QuickDeck In A New Tabpage",
    nargs = 0,
  })
  vim.api.nvim_create_user_command("AnkiQuickDeckEditNoteCustom", function() require("anki.api").edit_note_from_quick_deck({ display = "custom" }) end,
  {
    desc = "[Anki] Edit A Note On The QuickDeck Using The Custom Method",
    nargs = 0,
  })

  vim.api.nvim_create_user_command("AnkiQuickDeckCreate", function() require("anki.api").add_deck() end,
  {
    desc = "[Anki] Create a deck",
    nargs = 0,
  })

  vim.api.nvim_create_user_command("AnkiQuickDeckDeleteNote", function() require("anki.api").pick_note_to_delete_from_quick_deck() end,
  {
    desc = "[Anki] Delete A Note On The QuickDeck",
    nargs = 0,
  })

  vim.api.nvim_create_user_command("AnkiAddNote", function() require("anki.api").add_note() end,
  {
    desc = "[Anki] Create A Note In The Current Window",
    nargs = 0,
  })
  vim.api.nvim_create_user_command("AnkiAddNoteSplit", function() require("anki.api").add_note({ display = "split" }) end,
  {
    desc = "[Anki] Create A Note In A New Split",
    nargs = 0,
  })
  vim.api.nvim_create_user_command("AnkiAddNoteVsplit", function() require("anki.api").add_note({ display = "vsplit" }) end,
  {
    desc = "[Anki] Create A Note In A New Vsplit",
    nargs = 0,
  })
  vim.api.nvim_create_user_command("AnkiAddNoteTabpage", function() require("anki.api").add_note({ display = "tabpage" }) end,
  {
    desc = "[Anki] Create A Note In A New Tabapge",
    nargs = 0,
  })
  vim.api.nvim_create_user_command("AnkiAddNoteCustom", function() require("anki.api").add_note({ display = "custom" }) end,
  {
    desc = "[Anki] Create A Note Using The Custom Method",
    nargs = 0,
  })
  vim.api.nvim_create_user_command("AnkiEditNote", function() require("anki.api").edit_note() end,
  {
    desc = "[Anki] Edit A Note In The Current Window",
    nargs = 0,
  })
  vim.api.nvim_create_user_command("AnkiEditNoteSplit", function() require("anki.api").edit_note({ display = "split" }) end,
  {
    desc = "[Anki] Edit A Note In A New Split",
    nargs = 0,
  })
  vim.api.nvim_create_user_command("AnkiEditNoteVsplit", function() require("anki.api").edit_note({ display = "vsplit" }) end,
  {
    desc = "[Anki] Edit A Note In A New Vsplit",
    nargs = 0,
  })
  vim.api.nvim_create_user_command("AnkiEditNoteTabpage", function() require("anki.api").edit_note({ display = "tabpage" }) end,
  {
    desc = "[Anki] Edit A Note In A New Tabapge",
    nargs = 0,
  })
  vim.api.nvim_create_user_command("AnkiEditNoteCustom", function() require("anki.api").edit_note({ display = "custom" }) end,
  {
    desc = "[Anki] Edit A Note Using The Custom Method",
    nargs = 0,
  })
  vim.api.nvim_create_user_command("AnkiDeleteNote", function() require("anki.api").pick_delete_note() end,
  {
    desc = "[Anki] Delete A Note",
    nargs = 0,
  })
  vim.api.nvim_create_user_command("AnkiSelectQuickDeck", function() require("anki.api").select_state_quickdeck() end,
  {
    desc = "[Anki] Select The Deck",
    nargs = 0,
  })

  vim.api.nvim_create_user_command("AnkiInfos", function() require("anki.api").infos() end,
  {
    desc = "[Anki] Infos",
  })

  vim.api.nvim_create_user_command("AnkiCurrentKillNote", function() require("anki.api").kill_note(vim.api.nvim_get_current_buf()) end,
  {
    desc = "[Anki] Kill The Current Buffer Note",
    nargs = 0,
  })
  vim.api.nvim_create_user_command("AnkiCurrentSendNote", function() require("anki.api").send_note(vim.api.nvim_get_current_buf()) end,
  {
    desc = "[Anki] Send The Note Of The Current Buffer To Anki",
    nargs = 0,
  })
  vim.api.nvim_create_user_command("AnkiCurrentPullNote", function() require("anki.api").pull_note(vim.api.nvim_get_current_buf()) end,
  {
    desc = "[Anki] Pull The Current Buffer Note From Anki",
  })
  vim.api.nvim_create_user_command("AnkiCurrentDeleteNote", function() require("anki.api").delete_note(vim.api.nvim_get_current_buf()) end,
  {
    desc = "[Anki] Delete The Current Buffer Note From Anki",
  })

  vim.api.nvim_create_user_command("AnkiGUIBrowseToQuickDeck", function() require("anki.api").gui_deck() end,
  {
    desc = "[Anki] GUI Browse QuickDeck",
  })

  vim.api.nvim_create_user_command("AnkiGUIBrowseCurrentDeck", function() require("anki.api").gui_deck_current(vim.api.nvim_get_current_buf()) end,  
  {
    desc = "[Anki] GUI Browse Current Note Deck",
  })

  vim.api.nvim_create_user_command("AnkiGUIBrowseCurrentNote", function() require("anki.api").gui_note(vim.api.nvim_get_current_buf()) end,
  {
    desc = "[Anki] GUI Browse Current Note",
  })

end

