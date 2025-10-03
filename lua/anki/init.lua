local config = require("anki.config")
local api = require("anki.api")

local M = {}

local function set_keymap(mode, lhs, rhs, desc)
  vim.keymap.set(mode, lhs, rhs, { noremap = true, silent = true, desc = "[Anki] " .. desc })
end

---Sets up the default keymaps if enabled in the config.
local function setup_mappings()
  if not config.options.default_mappings then
    return
  end

  local prefix = config.options.prefix
  local which_key_ok, which_key = pcall(require, "which-key")

  -- A table to define our mappings. This avoids tons of repetition!
  local mappings = {
    -- QuickDeck Add Note
    { "a", "QuickDeck Add Note", {
      { "b", function() api.add_note_to_quick_deck() end, "Buffer" },
      { "s", function() api.add_note_to_quick_deck({ display = "split" }) end, "Split" },
      { "v", function() api.add_note_to_quick_deck({ display = "vsplit" }) end, "VSplit" },
      { "t", function() api.add_note_to_quick_deck({ display = "tabpage" }) end, "Tabpage" },
      { "c", function() api.add_note_to_quick_deck({ display = "custom" }) end, "Custom", config.options.custom_display },
    }},
    -- QuickDeck Edit Note
    { "e", "QuickDeck Edit Note", {
      { "b", function() api.edit_note_from_quick_deck() end, "Buffer" },
      { "s", function() api.edit_note_from_quick_deck({ display = "split" }) end, "Split" },
      { "v", function() api.edit_note_from_quick_deck({ display = "vsplit" }) end, "VSplit" },
      { "t", function() api.edit_note_from_quick_deck({ display = "tabpage" }) end, "Tabpage" },
      { "c", function() api.edit_note_from_quick_deck({ display = "custom" }) end, "Custom", config.options.custom_display },
    }},
    -- Add Note
    { "A", "Add Note", {
      { "b", function() api.add_note() end, "Buffer" },
      { "s", function() api.add_note({ display = "split" }) end, "Split" },
      { "v", function() api.add_note({ display = "vsplit" }) end, "VSplit" },
      { "t", function() api.add_note({ display = "tabpage" }) end, "Tabpage" },
      { "c", function() api.add_note({ display = "custom" }) end, "Custom", config.options.custom_display },
    }},
    -- Edit Note
    { "E", "Edit Note", {
      { "b", function() api.edit_note() end, "Buffer" },
      { "s", function() api.edit_note({ display = "split" }) end, "Split" },
      { "v", function() api.edit_note({ display = "vsplit" }) end, "VSplit" },
      { "t", function() api.edit_note({ display = "tabpage" }) end, "Tabpage" },
      { "c", function() api.edit_note({ display = "custom" }) end, "Custom", config.options.custom_display },
    }},
    -- GUI Browse
    { "b", "GUI Browse", {
      { "q", function() api.gui_deck() end, "To QuickDeck" },
      { "d", function() api.gui_deck_current(vim.api.nvim_get_current_buf()) end, "To Current Note Deck" },
      { "n", function() api.gui_note(vim.api.nvim_get_current_buf()) end, "To Current Note" },
    }},
  }

  -- Single mappings
  local single_mappings = {
    { "d", function() api.pick_notes_to_delete_from_quick_deck() end, "QuickDeck Delete Notes" },
    { "D", function() api.pick_delete_notes() end, "Delete Notes" },
    { "q", function() api.select_state_quickdeck() end, "Select QuickDeck" },
    { "i", function() api.infos() end, "Infos" },
    { "c", function() api.add_deck() end, "Deck Create" },
    { "k", function() api.kill_note(vim.api.nvim_get_current_buf()) end, "Kill Current Note" },
    { "K", function() api.kill_all() end, "Kill All Notes" },
    { "w", function() api.send_note(vim.api.nvim_get_current_buf()) end, "Send Current Note" },
    { "p", function() api.pull_note(vim.api.nvim_get_current_buf()) end, "Pull Current Note" },
    { "r", function() api.delete_note(vim.api.nvim_get_current_buf()) end, "Delete Current Note" },
  }

  if which_key_ok then
    local wk_maps = { mode = { "n" }, { prefix, group = "[ANKI]" } }
    for _, group in ipairs(mappings) do
      local group_key, group_desc, sub_mappings = unpack(group)
      table.insert(wk_maps, { prefix .. group_key, group = "[ANKI] " .. group_desc })
      for _, map in ipairs(sub_mappings) do
        local key, rhs, desc, condition = unpack(map)
        if condition == nil or condition then -- Check if the mapping should be created
          table.insert(wk_maps, { prefix .. group_key .. key, rhs, desc = desc })
        end
      end
    end
    for _, map in ipairs(single_mappings) do
      local key, rhs, desc = unpack(map)
      table.insert(wk_maps, { prefix .. key, rhs, desc = desc })
    end
    which_key.add(wk_maps)
  else -- Fallback to standard vim.keymap.set
    for _, group in ipairs(mappings) do
      local group_key, _, sub_mappings = unpack(group)
      for _, map in ipairs(sub_mappings) do
        local key, rhs, desc, condition = unpack(map)
        if condition == nil or condition then
          set_keymap("n", prefix .. group_key .. key, rhs, desc)
        end
      end
    end
    for _, map in ipairs(single_mappings) do
      local key, rhs, desc = unpack(map)
      set_keymap("n", prefix .. key, rhs, desc)
    end
  end
end

---Sets up user commands if enabled.
local function setup_commands()
  if not config.options.create_user_commands then
    return
  end

  local commands = {
    { "AnkiQuickDeckAddNote", function() api.add_note_to_quick_deck() end, "Create a note on the QuickDeck" },
    { "AnkiQuickDeckEditNote", function() api.edit_note_from_quick_deck() end, "Edit a note on the QuickDeck" },
    { "AnkiAddNote", function() api.add_note() end, "Create a note" },
    { "AnkiEditNote", function() api.edit_note() end, "Edit a note" },
  }

  local single_commands = {
    { "AnkiDeckCreate", function() api.add_deck() end, "Create a deck" },
    { "AnkiQuickDeckDeleteNote", function() api.pick_notes_to_delete_from_quick_deck() end, "Delete a note on the QuickDeck" },
    { "AnkiDeleteNote", function() api.pick_delete_notes() end, "Delete a note" },
    { "AnkiSelectQuickDeck", function() api.select_state_quickdeck() end, "Select the QuickDeck"},
    { "AnkiInfos", function() api.infos() end, "Infos"},
    { "AnkiKillNote", function() api.kill_note(vim.api.nvim_get_current_buf()) end, "Kill note buffers"},
    { "AnkiKillAll", function() api.kill_all() end, "Kill all the notes buffers"},
    { "AnkiCurrentSendNote", function() api.send_note(vim.api.nvim_get_current_buf()) end, "Send the note of to anki"},
    { "AnkiCurrentPullNote", function() api.pull_note(vim.api.nvim_get_current_buf()) end, "Pull the note from anki"},
    { "AnkiCurrentDeleteNote", function() api.delete_note(vim.api.nvim_get_current_buf()) end, "Delete the note from anki"},
    { "AnkiGUIBrowseToQuickDeck", function() api.gui_deck() end, "Go to the QuickDeck in the GUI"},
    { "AnkiGUIBrowseCurrentDeck", function() api.gui_deck_current(vim.api.nvim_get_current_buf()) end, "Go to the deck of the current note in the GUI"},
    { "AnkiGUIBrowseCurrentNote", function() api.gui_note(vim.api.nvim_get_current_buf()) end, "Go to the current note in the GUI"},
  }

  -- Loop to create commands with display options
  for _, cmd_def in ipairs(commands) do
    local name, func, desc = unpack(cmd_def)
    local displays = {
      { "", "", "in the current window" },
      { "Split", { display = "split" }, "in a new split" },
      { "Vsplit", { display = "vsplit" }, "in a new vsplit" },
      { "Tabpage", { display = "tabpage" }, "in a new tabpage" },
    }
    -- Conditionally add the custom display
    if config.options.custom_display then
      table.insert(displays, { "Custom", { display = "custom" }, "using the custom method" })
    end

    for _, display_info in ipairs(displays) do
      local suffix, args, desc_suffix = unpack(display_info)
      vim.api.nvim_create_user_command(name .. suffix, function() func(args) end, {
        desc = "[Anki] " .. desc .. " " .. desc_suffix,
        nargs = 0,
      })
    end
  end
  
  -- Create all other simple commands
  for _, cmd_def in ipairs(single_commands) do
    local name, func, desc = unpack(cmd_def)
    vim.api.nvim_create_user_command(name, func, { desc = "[Anki] " .. desc, nargs = 0 })
  end
end


---@param opts table? User configuration options.
function M.setup(opts)
  config.setup(opts)
  setup_mappings()
  setup_commands()

  -- setup default quickdeck in state
  require("anki.state").quickdeck = config.options.quickdeck

end

return M
