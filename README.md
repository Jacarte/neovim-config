# Neovim configuration with Lua

A [Neovim](https://github.com/neovim/neovim) configuration using Lua, with the minimal number of plugins I need for programming. Different language servers available through the LSP protocol provide code completion and analysis.

This readme exists so I don't have to remember how to do all these things when setting up a new machine.

## Requirements

- Neovim **>= 0.12** (required by nvim-treesitter `main` and the native LSP API used here)
- [`tree-sitter-cli`](https://github.com/tree-sitter/tree-sitter/blob/master/crates/cli/README.md) **>= 0.26.1** — provides the `tree-sitter` command; install it through the system package manager, not npm; this setup is currently verified with **0.26.11**
- `curl` and `tar` — required to download and extract parsers
- A C compiler — required to build parsers
- `npm` / `node` — most language servers install via npm
- `opencode` — for the AI-powered config Q&A feature

## Setting up

### Linux

```bash
# Stable
sudo snap install --beta nvim --classic

# Nightly
sudo snap install --edge nvim --classic
```

**Server color fix:** `export TERM=xterm-256color; export TERM=screen-256color-bce; alias tmux='tmux -2'`

Install npm:
```bash
sudo apt install npm
```

Install opencode:
```bash
npm install -g @opencode-ai/cli
```

### MacOS

```bash
# Stable
brew install neovim

# tree-sitter-cli (required by nvim-treesitter)
brew install tree-sitter-cli

# Nightly
brew install --HEAD neovim

# Update
brew reinstall neovim
```

**iTerm2**: `Preferences → Profiles → Keys` → set Left Option to `Esc+`.  
**kitty**: set `macos_option_as_alt left` in kitty config, then restart (`Command + Q`).

Install opencode:
```bash
npm install -g @opencode-ai/cli
```

## Git

We use [lazygit](https://github.com/jesseduffield/lazygit) for git integration. Make sure you have it installed.

## Installing the configuration

```bash
git clone https://github.com/Jacarte/neovim-config.git ~/.config/nvim
cd ~/.config/nvim
```

The folder structure:

```
|- lua
|  |- lsp/
|  |- plugins/
|  |- changed_files.lua
|  |- commands.lua
|  |- keymaps.lua
|  |- opencode_ask.lua
|  |- options.lua
|  |- plugins.lua
|  |- telescope_resume.lua
|  |- themes.lua
|  \- utils.lua
|- plugin/
\- init.lua
```

The file `init.lua` loads all modules. `plugins.lua` declares all plugins via [packer](https://github.com/wbthomason/packer.nvim). Files under `lua/plugins/` contain per-plugin configuration. Files under `lua/lsp/` configure individual language servers.

### Key plugins

| Plugin | Purpose |
|--------|---------|
| [packer](https://github.com/wbthomason/packer.nvim) | Plugin manager |
| [nvim-lspconfig](https://github.com/neovim/nvim-lspconfig) | LSP server definitions (used with `vim.lsp.config` native API) |
| [mason](https://github.com/williamboman/mason.nvim) + [mason-lspconfig](https://github.com/williamboman/mason-lspconfig.nvim) | Install and manage LSP server binaries |
| [nvim-cmp](https://github.com/hrsh7th/nvim-cmp) | Auto-complete |
| [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter) | Syntax highlighting |
| [nvim-tree](https://github.com/nvim-tree/nvim-tree.lua) | File explorer |
| [telescope](https://github.com/nvim-telescope/telescope.nvim) | Fuzzy finder (`<leader>ff` / `<leader>fg`) |
| [harpoon](https://github.com/ThePrimeagen/harpoon) | File bookmarks with exact line+column position |
| [fugitive](https://github.com/tpope/vim-fugitive) | Git integration |
| [gitsigns](https://github.com/lewis6991/gitsigns.nvim) | Git gutter and hunk management |
| [lualine](https://github.com/nvim-lualine/lualine.nvim) | Status line |
| [copilot](https://github.com/zbirenbaum/copilot.lua) | GitHub Copilot |
| [toggleterm](https://github.com/akinsho/toggleterm.nvim) | Terminal management |
| [snacks.nvim](https://github.com/folke/snacks.nvim) | UI utilities |

Adding a new plugin with standard config:

```lua
use({
  '<author>/<plugin-repo>',
  config = function() require('<plugin-name>').setup({}) end,
})
```

For complex config, create `lua/plugins/foo.lua` and load it:

```lua
use({
  '<author>/<plugin-repo>',
  config = function() require('plugins/foo') end,
  requires = '<author>/<required-plugin-repo>'
})
```

## LSP setup

Language servers are configured using Neovim's native LSP API (≥ 0.11). nvim-lspconfig provides server definitions; servers are activated with `vim.lsp.config` + `vim.lsp.enable`.

Server binaries are installed via **mason** (`:Mason` to open the UI). The `lua/plugins/mason-lspconfig.lua` file lists servers to auto-install.

Per-language configuration lives in `lua/lsp/`:

| File | Servers |
|------|---------|
| `lua/plugins/lspconfig.lua` | bashls, clangd, pyright, jsonls, dockerls |
| `lua/lsp/ts.lua` | ts_ls (TypeScript/JS), eslint |
| `lua/lsp/golang.lua` | gopls |
| `lua/lsp/rust.lua` | rustaceanvim |

The common `on_attach` function (key mappings, diagnostics) lives in `lua/lsp/utils.lua`.

### Installing language server binaries

Most servers install automatically via mason. For manual reference:

- **Bash** (`bashls`): `npm i -g bash-language-server`
- **C/C++** (`clangd`): `sudo apt-get install clangd-13` (Linux) or via XCode (macOS)
- **Docker** (`dockerls`): `npm i -g dockerfile-language-server-nodejs`
- **JSON** (`jsonls`): `npm i -g vscode-langservers-extracted`
- **Python** (`pyright`): `npm i -g pyright`
- **TypeScript/JS** (`ts_ls`): `npm i -g typescript-language-server typescript`
- **Go** (`gopls`): `go install golang.org/x/tools/gopls@latest`
- **Lua** (`lua_ls`): install via `:Mason` → `lua-language-server`

If npm complains about an old node version:
```bash
sudo npm cache clean -f
sudo npm install -g n
sudo n stable
```

### Inline diagnostics

Inline error messages are disabled by default (they create clutter). To re-enable, comment out the relevant line in `lua/options.lua` around line 34.

## Harpoon

[Harpoon](https://github.com/ThePrimeagen/harpoon) (v2) is configured for exact-position bookmarks — each bookmark remembers its file, line, **and** column.

- Same file at different line/col positions creates distinct entries.
- Selecting a bookmark always jumps to the exact saved position, even when the buffer is already open.
- Display format: `filename:line:col`

Config: `lua/plugins/harpoon.lua`

## Telescope

`<leader>ff` and `<leader>fg` resume their previous in-session picker state instead of always opening fresh. Switching between the two starts fresh (no cross-contamination).

Config: `lua/telescope_resume.lua`, `lua/plugins/telescope.lua`

## Auto-completion

`nvim-cmp` attaches language servers to buffers. The common `on_attach` function in `lua/lsp/utils.lua` enables key mappings for code completion across all servers.

## Squire AI completion

[Squire](https://github.com/jibinjacob09/squire.nvim) is configured here as a local AI completion layer backed by the OpenCode Go endpoint.

- Manual trigger: `<C-Space>`
- Terminal fallback trigger: `<C-@>`
- Accept suggestion: `<C-l>`
- Dismiss suggestion: `<Esc>`

This setup supports multiline completions, but it strips model reasoning and leading blank lines before rendering the suggestion. In practice, that means the suggestion starts with code instead of explanation text or an empty first line.

Auto-completion is implemented locally on top of Squire with a 400ms debounce after insert-mode text changes.

- `:SquireAutoEnable` turns debounced auto-completion on.
- `:SquireAutoDisable` turns debounced auto-completion off.
- `:SquireHealthcheck` verifies that the local Squire provider can reach the API successfully.

Auto-completion only runs for the configured filetypes in `lua/plugins/squire.lua`, and manual completion still works even when auto mode is disabled.

Config: `lua/plugins/squire.lua`

## AI-Powered Config Q&A (opencode_ask)

Press `<leader>oc` to open an interactive Q&A interface. Ask questions about your Neovim config (keybindings, features, settings) and get instant answers powered by AI. The system:

- Searches `keymaps.lua`, `plugins.lua`, `options.lua`, and other config files
- Caches answers locally for fast re-queries
- Uses the `opencode` CLI with the `nvim-explorer` agent

**Requires** `opencode` CLI installed globally (`npm install -g @opencode-ai/cli`).

## OpenCode plugin patch (required)

This config applies a local patch to `opencode.nvim` on install/update. The patch lives in `lua/plugins/opencode_patch.lua` and is applied in:

- `lua/plugins.lua` (plugin `run` hook)
- `lua/plugins/opencode.lua` (runtime safety re-apply)

The patch adds safer window handling and extra interrupt keymaps (`<C-Esc>`, `<C-[>`).

Re-apply manually if needed:

```vim
:lua require("plugins.opencode_patch").apply()
```

Then restart Neovim.

## Web-dev Icons

Install a [Nerd Font](https://github.com/ryanoasis/nerd-fonts) for icons and separators:

1. Download a font from the repo (e.g. Roboto Mono).
2. Copy to:
   - Linux: `~/.local/share/fonts/`
   - macOS: `/Library/Fonts/`
3. Change the terminal font to the patched font.

### Nerd Fonts with kitty

kitty patches fonts itself. Follow this [guide](https://erwin.co/kitty-and-nerd-fonts/#symbols):

1. Download `Symbols-2048-em Nerd Font Complete.ttf` and place in `Library/Fonts/`.
2. Specify glyphs manually if they don't appear by default.
3. Refresh font cache.

## Fix kitty

To use kitty-based tab terminals (`<leader>t`), create a kitty launch config per [these instructions](https://sw.kovidgoyal.net/kitty/faq/#how-do-i-specify-command-line-options-for-kitty-on-macos) with content:

```
kitty -o allow_remote_control=yes -o enabled_layouts=tall --listen-on unix:/tmp/kitten
```

## TODO

Improvements:
- Only open diagnostics if there are any to show.

LSPs to add:
- LaTeX: [texlab](https://github.com/latex-lsp/texlab) (already in mason ensure_installed).

Plugins to try:
- [Rnvimr](https://github.com/kevinhwang91/rnvimr): Ranger in a floating buffer.
- [rhubarb.vim](https://github.com/tpope/rhubarb.vim): GBrowse support for fugitive.
- [trouble.nvim](https://github.com/folke/trouble.nvim): Better quickfix/loclist UI.

## Attributions

The structure of this config was based on [yashguptaz](https://github.com/yashguptaz/)'s [config](https://github.com/yashguptaz/nvy) and tutorial.
