# Anki.nvim

Anki.nvim is a Neovim plugin that allows you to interact with Anki using [AnkiConnect](https://git.sr.ht/~foosoft/anki-connecthttps://git.sr.ht/~foosoft/anki-connect).
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

## Features

-   Three-pane UI: Navigate decks, notes, and edit content in a file-explorer-like interface within Neovim.
-   Persistent 'Default' Deck: The 'Default' deck will always appear in the deck pane, even if deleted, because Anki automatically recreates it as needed.
-   Deck Management: Create, rename, and delete Anki decks from within Neovim.
-   Note Management: Create, edit, move and delete notes in any deck.
-   Model Selection: Choose the note model when creating notes.
-   Open in Anki GUI: Jump directly to the selected deck or note in the Anki desktop application.
-   Automatic UI Refresh: Deck and notes list refresh automatically after changes

## Dependencies

-   [lua-http](https://github.com/daurnimator/lua-http)
-   [AnkiConnect](https://ankiweb.net/shared/info/2055492159) (Anki Add-on)

## Installation

Using `lazy.nvim`:

``` lua
{
  "0fflineuser/anki.nvim",
  dependencies = {
    {
      "vhyrro/luarocks.nvim",
      priority = 1000,
      opts = {
        rocks = { "http" },
      },
    },
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
      send_note = "<leader>w",
      pull_note = "<leader>p",
      delete_note = "<leader>r",
      kill_note = "<leader>k",
      show_help = "?",
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

### Note Browser Keymaps

  | Keymap | Description                               |
  |--------|-------------------------------------------|
  | `?`    | Show this help window                     |
  | `q`    | Close the Anki UI tab                     |
  | `<CR>` | Edit the selected note in the editor pane |
  | `d`    | Delete the selected note                  |
  | `o`    | Open the selected note in the Anki GUI    |
  | `r`    | Refresh notes                             |

### Note Editor Keymaps

  | Keymap       | Description                                       |
  |--------------|---------------------------------------------------|
  | `?`          | Show this help window                             |
  | `<leader>w`  | \*W\*rite/Send the current note to Anki           |
  | `<leader>pw` | \*P\*ull the latest version of the note from Anki |
  | `<leader>rw` | \*R\*emove/Delete the note from Anki              |
  | `<leader>kw` | \*K\*ill/Close the note editor buffers            |

