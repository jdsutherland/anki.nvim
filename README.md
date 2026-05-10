# Anki.nvim

Anki.nvim is a Neovim plugin that allows you to interact with Anki using [AnkiConnect](https://git.sr.ht/~foosoft/anki-connect).
It allows you to create, edit, and manage your Anki notes and decks directly from neovim.

## Table of Contents

-   [*Features*](#features)
-   [*Dependencies*](#dependencies)
-   [*Installation*](#installation)
-   [*Configuration*](#configuration)
-   [*Usage*](#usage)
-   [*Deck Browser Keymaps*](#deck-browser-keymaps)
-   [*Note Browser Keymaps*](#note-browser-keymaps)
-   [*Note Editor Keymaps*](#note-editor-keymaps)
-   [*Media Browser Keymaps*](#media-browser-keymaps)

## Features

-   Three-pane UI: Navigate decks, notes, and edit content in a file-explorer-like interface within Neovim.
-   Persistent 'Default' Deck: The 'Default' deck will always appear in the deck pane, even if deleted, because Anki automatically recreates it as needed.
-   Deck Management: Create, rename, and delete Anki decks from within Neovim.
-   Note Management: Create, edit, move and delete notes in any deck.
-   Model Selection: Choose the note model when creating notes.
-   Profile Switching: Switch between different Anki profiles without leaving Neovim.
-   Open in Anki GUI: Jump directly to the selected deck or note in the Anki desktop application.
-   Media Attachments: Attach images, audio, and video to notes from local files, URLs, clipboard, or Anki's media collection.
-   Media Browser: Browse Anki's media collection in a floating two-pane window with image preview support via [snacks.nvim](https://github.com/folke/snacks.nvim).
-   Automatic UI Refresh: Deck and notes list refresh automatically after changes.

## Dependencies

-   [plenary.nvim](https://github.com/nvim-lua/plenary.nvim)
-   [AnkiConnect](https://ankiweb.net/shared/info/2055492159) (Anki Add-on)

### Optional

-   [snacks.nvim](https://github.com/folke/snacks.nvim) — For image preview in the media browser. Falls back to a metadata-only display if not installed or if the terminal does not support image protocols.

## Installation

Using `lazy.nvim`:

``` lua
{
  "0fflineuser/anki.nvim",
   dependencies = {
       "nvim-lua/plenary.nvim",
       "folke/snacks.nvim" -- optional, for image preview
   },
  opts = {
    -- Your custom configuration goes here
  },
  config = true
}
```

## Configuration

You can customize the plugin by passing a table to the `setup()` function. Here are the default options:

``` lua
require("anki").setup({
  -- The URL of your AnkiConnect server
  url = "http://localhost:8765",
  -- The timeout for requests to AnkiConnect, in milliseconds
  timeout = 500,
  -- The key to open the 'Anki UI' tab
  prefix = "<leader>a",
  -- Automatically map the 'Anki UI' to 'prefix'
  default_mappings = true,
  -- Whether to automatically open the Anki GUI to the relevant deck/note
  gui_browse_enabled = true,
  -- Whether to create the 'Anki' command
  create_user_commands = true,
  -- Use the floating media browser with image preview when browsing Anki media.
  -- Falls back to vim.ui.select if disabled or if snacks.nvim is unavailable.
  media_browser_preview = true,
  -- Function to format a note for display in the note list
  note_formatter = function(note)
    local display = ""
    for key, field in pairs(note.fields) do
      display = display .. " [" .. key .. "]> " .. string.gsub(field.value, "[\r\n]", " ")
    end
    return display
  end,
  -- Floating media browser window configuration
  media_browser = {
    -- Total width as fraction of &columns
    width = 0.85,
    -- Total height as fraction of &lines
    height = 0.8,
    -- List pane width as fraction of total width
    list_width = 0.35,
    -- Border style for nvim_open_win (see :help nvim_open_win)
    border = "single",
    -- Window titles
    list_title = " Media ",
    preview_title = " Preview ",
    -- Window-local options for the list pane
    list_win_opts = { cursorline = true, wrap = false },
    -- Window-local options for the preview pane
    preview_win_opts = { wrap = false, number = false, relativenumber = false, signcolumn = "no" },
  },
  -- Keymappings for the deck, note, and editor panes
  mappings = {
    deck = {
      show_help = "?",
      close = "q",
      select_deck = "<CR>",
      delete_deck = "d",
      create_deck = "c",
      add_note = "a",
      rename_deck = "m",
      gui_deck = "o",
      refresh_decks = "r",
      switch_profile = "p",
    },
    note = {
      show_help = "?",
      close = "q",
      edit_note = "<CR>",
      delete_note = "d",
      gui_note = "o",
      show_all_notes = "a",
      refresh_notes = "r",
      move_note_to_deck = "m",
    },
    editor = {
      show_help = "?",
      send_note = "<leader>w",
      pull_note = "<leader>p",
      delete_note = "<leader>r",
      kill_note = "<leader>k",
      attach_media = "<leader>m",
    },
  },
})
```

## Usage

The plugin is centered around a single command, `:Anki`, which opens a dedicated UI in a new tab.

This UI has three panes:

-   **Notes** (top-left): A list of notes in the selected deck.
-   **Decks** (bottom-left): A file-explorer view of your decks.
-   **Editor** (right): Where the note editor opens.

Each pane has its own set of keymaps.
You can press `?` in any pane to see the available shortcuts for that specific context.
These keymaps are configurable, see the `Configuration` section.

### Deck Browser Keymaps

 | Keymap | Description                             |
 |--------|-----------------------------------------|
 | `?`    | Show this help window                   |
 | `q`    | Close the Anki UI tab                   |
 | `<CR>` | Select a deck and show its notes        |
 | `d`    | Delete deck under cursor                |
 | `c`    | Create a deck                           |
 | `a`    | Add a note to the deck under the cursor |
 | `m`    | Rename deck under the cursor            |
 | `o`    | Open the selected deck in the Anki GUI  |
 | `r`    | Refresh decks                           |
 | `p`    | Switch Anki profile                     |

### Note Browser Keymaps

  | Keymap | Description                               |
  |--------|-------------------------------------------|
  | `?`    | Show this help window                     |
  | `q`    | Close the Anki UI tab                     |
  | `<CR>` | Edit the selected note in the editor pane |
  | `d`    | Delete the selected note                  |
  | `o`    | Open the selected note in the Anki GUI    |
  | `a`    | Show all notes across decks               |
  | `r`    | Refresh notes                             |
  | `m`    | Move the selected note to another deck    |

### Note Editor Keymaps

  | Keymap       | Description                                       |
  |--------------|---------------------------------------------------|
  | `?`          | Show this help window                             |
  | `<leader>w`  | \*W\*rite/Send the current note to Anki           |
  | `<leader>p`  | \*P\*ull the latest version of the note from Anki |
  | `<leader>r`  | \*R\*emove/Delete the note from Anki              |
  | `<leader>k`  | \*K\*ill/Close the note editor buffers            |
  | `<leader>m`  | \*M\*edia/Attach media to the current field        |

### Media Browser Keymaps

The media browser is a floating two-pane window (file list on the left, preview on the right) that opens when you select "Browse Anki media" from the media attachment menu. Images are previewed inline when [snacks.nvim](https://github.com/folke/snacks.nvim) is installed and the terminal supports image protocols; otherwise, file metadata (name, type, extension) is shown.

  | Keymap    | Description                              |
  |-----------|------------------------------------------|
  | `<CR>`    | Insert the selected media reference      |
  | `q`       | Close the media browser                  |
  | `<Esc>`   | Close the media browser                  |
  | `?`       | Show help window                        |
  | `j`/`k`   | Navigate the file list (standard movement) |

The media browser can be disabled (falling back to `vim.ui.select`) by setting `media_browser_preview = false` in the config. The window layout and appearance can be customized via the `media_browser` config table (see [Configuration](#configuration)).
