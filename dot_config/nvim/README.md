# My Neovim Config

## Color Scheme

[kanagawa-paper](https://github.com/thesimonho/kanagawa-paper.nvim)

![screenshot](https://i.imgur.com/JhCthBr.png)

## General Settings

| Type | Setting | Value | Description |
|------|---------|-------|-------------|
| Global | `guifont` | `"Cascadia Code:h13"` | Sets the GUI font |
| Global | `mapleader` | `,` | Sets the leader key |
| Option | `shiftwidth` | `2` | Sets the number of spaces used for each step of (auto)indent |
| Option | `ignorecase` | `true` | Ignores case in search patterns |
| Option | `number` | `true` | Displays line numbers |
| Option | `relativenumber` | `true` | Displays line numbers relative to the cursor |
| Option | `mouse` | `""` | Disables mouse support |
| Option | `scrolloff` | `4` | Keeps 4 lines visible above/below cursor when scrolling |
| Option | `undofile` | `true` | Enables persistent undo history |
| Option | `smartindent` | `true` | Enables smart auto-indentation |
| Option | `cursorline` | `true` | Highlights the current line |
| Option | `splitright` | `true` | Opens vertical splits to the right |
| Option | `splitbelow` | `true` | Opens horizontal splits below |

## Language-Specific Settings

### Go

| Setting | Value | Description |
|---------|-------|-------------|
| `shiftwidth` | `4` | Sets the number of spaces for indentation in Go files |
| `tabstop` | `4` | Sets the width of a tab character in Go files |
| `expandtab` | `true` | Converts tabs to spaces in Go files |

## LSP Configuration

The config uses native Neovim LSP with the following features:
- Auto-formatting on save
- Rounded borders for LSP windows
- Virtual diagnostic lines
- Configured language servers:
  - `gopls` (Go)

## General Mappings

> Leader key: `,`

| Mode | Key Combination | Description |
|------|-----------------|-------------|
| Normal | `K`  | Trigger LSP hover information for the symbol under the cursor |
| Normal | `<CR>` | Clears the search highlight |
| Normal | `<leader>q` | Closes the current buffer and switches to the next one |
| Normal | `<c-s>` | Saves the current file |
| Insert | `<c-s>` | Exits insert mode and saves the current file |
| Terminal | `<Esc>` | Exits terminal mode |
| Normal | `<leader>ca` | Execute code actions suggested by the LSP server |
| Normal | `<leader>rn` | Rename the symbol under the cursor using LSP capabilities |
| Normal | `<leader>gd` | Jump to the definition of the symbol under the cursor |
| Normal | `<leader>gi` | Jump to the implementation of the symbol under the cursor |
| Visual | `<leader>y` | Copy selection to system clipboard |
| Normal | `<leader>p` | Paste from system clipboard |
| Normal | `<C-n>` | Toggle NvimTree file explorer |

## Fuzzy Finder (FZF) Mappings

| Mode | Key Combination | Description |
|------|-----------------|-------------|
| Normal | `<leader>ff` | Find files in current working directory |
| Normal | `<leader>fg` | Live grep across files |
| Normal | `<leader>fb` | Find in current buffer |
| Normal | `<leader>fm` | Find marks |
| Normal | `<leader>f<` | Resume previous find |
| Normal | `<leader>fo` | Find open buffers |
| Normal | `<leader>fr` | Find LSP references |

## Plugins

| Plugin | Description | Link |
|--------|-------------|------|
| kanagawa-paper.nvim | A light theme variant of the Kanagawa colorscheme | [GitHub](https://github.com/thesimonho/kanagawa-paper.nvim) |
| blink.cmp | Modern completion menu with snippets support | [GitHub](https://github.com/saghen/blink.cmp) |
| fzf-lua | Fuzzy finder for Neovim | [GitHub](https://github.com/ibhagwan/fzf-lua) |
| lualine.nvim | A blazing fast and easy to configure Neovim statusline plugin written in Lua | [GitHub](https://github.com/nvim-lualine/lualine.nvim) |
| nvim-web-devicons | A Lua fork of vim-devicons for Neovim, providing file icons | [GitHub](https://github.com/kyazdani42/nvim-web-devicons) |
| nvim-tree.lua | A file explorer tree for Neovim written in Lua | [GitHub](https://github.com/kyazdani42/nvim-tree.lua) |
| lazy.nvim | A modern plugin manager for Neovim | [GitHub](https://github.com/folke/lazy.nvim) |
