# OpenCode Plan: Add `conform.nvim` with Biome Support

## Objective

Integrate [`stevearc/conform.nvim`](https://github.com/stevearc/conform.nvim) into this Neovim configuration and make it the single formatting entry point.

The implementation must:

- use the existing Packer-based plugin structure;
- preserve the formatter behavior already provided by LSP servers;
- use Biome for supported web filetypes when the project explicitly contains a Biome configuration;
- avoid duplicate format-on-save autocmds;
- keep formatting synchronous during `BufWritePre` so the formatted content is included in the write;
- avoid unrelated plugin-manager or LSP refactors.

## Repository Context

Relevant files:

- `init.lua`
  - loads the top-level modules;
  - currently contains a global `BufWritePre` callback using `vim.lsp.buf.format()`.
- `lua/plugins.lua`
  - contains Packer plugin declarations.
- `lua/lsp/rust.lua`
  - currently contains a second Rust-only format-on-save autocmd.
- `lua/plugins/`
  - contains plugin-specific configuration modules.

The existing global formatting callback uses `async = true` during `BufWritePre`. This can apply edits after the original write has completed. The Rust-specific hook also creates a second formatting path.

## Desired Formatting Matrix

| Filetype | Formatter strategy |
| --- | --- |
| JavaScript / JSX | Biome when a Biome config exists; otherwise LSP fallback |
| TypeScript / TSX | Biome when a Biome config exists; otherwise LSP fallback |
| JSON / JSONC | Biome when a Biome config exists; otherwise LSP fallback |
| CSS | Biome when a Biome config exists; otherwise LSP fallback |
| GraphQL | Biome when a Biome config exists; otherwise LSP fallback |
| Go | First available of `goimports`, then `gofmt`; otherwise LSP fallback |
| Python | Black; otherwise LSP fallback |
| Rust | rustfmt; otherwise LSP fallback |
| Lua | StyLua; otherwise LSP fallback |
| Other filetypes | Attached LSP formatter fallback |

Biome must not run in arbitrary JavaScript or TypeScript projects that do not use Biome.

Recognized Biome configuration files:

- `biome.json`
- `biome.jsonc`
- `.biome.json`
- `.biome.jsonc`

## Implementation Steps

### 1. Add the plugin declaration

Add `stevearc/conform.nvim` through the existing Packer setup.

Prefer a small loader module consistent with the repository structure, for example:

- `lua/plugins/conform_spec.lua` for the Packer declaration;
- `lua/plugins/conform.lua` for plugin configuration.

The Packer declaration should call:

```lua
require("plugins.conform").setup()
```

Do not migrate the repository from Packer to another plugin manager as part of this task.

### 2. Load the Conform plugin specification

Load the Conform Packer declaration after `require('plugins')` in `init.lua`, following the repository's current module-loading approach.

Do not place formatter setup directly inside `init.lua`.

### 3. Configure formatters by filetype

In `lua/plugins/conform.lua`, configure `formatters_by_ft` for:

- `javascript`
- `javascriptreact`
- `typescript`
- `typescriptreact`
- `json`
- `jsonc`
- `css`
- `graphql`
- `go`
- `python`
- `rust`
- `lua`

Use Conform's built-in formatter definitions rather than reimplementing formatter commands.

For Go, configure the list so only the first available formatter runs:

```lua
go = { "goimports", "gofmt", stop_after_first = true }
```

### 4. Make Biome project-aware

Use Conform's built-in `biome` formatter and set:

```lua
formatters = {
  biome = {
    require_cwd = true,
  },
}
```

The built-in formatter already detects Biome configuration files. `require_cwd = true` ensures Biome is skipped when no Biome project root is found.

Do not globally install or force a fallback Biome configuration.

Conform should fall back to an attached LSP formatter when Biome is unavailable for the current buffer.

### 5. Configure format-on-save

Use Conform's `format_on_save` option:

```lua
format_on_save = {
  timeout_ms = 1000,
  lsp_format = "fallback",
}
```

Also configure:

```lua
default_format_opts = {
  lsp_format = "fallback",
}
```

Formatting during save must remain synchronous. Do not set `async = true` in the save path.

Set `notify_no_formatters = false` so unsupported buffers do not produce noisy notifications.

### 6. Remove duplicate formatting autocmds

Remove the global formatting autocmd from `init.lua`:

```lua
vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = "*",
  callback = function()
    vim.lsp.buf.format({ async = true })
  end
})
```

Remove the Rust-specific `BufWritePre` formatting group from `lua/lsp/rust.lua`.

After this change, Conform must be the only component responsible for format-on-save.

Do not disable LSP formatting capabilities. They are still required as fallback formatters.

### 7. Add manual formatting

Add a normal-mode mapping:

```lua
<leader>cf
```

It should call:

```lua
require("conform").format({
  async = true,
  lsp_format = "fallback",
})
```

The manual command may be asynchronous because it is not part of the write lifecycle.

Use a descriptive mapping label such as `Format buffer`.

### 8. Configure `formatexpr`

Set:

```lua
vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"
```

This allows `gq` and other format-expression consumers to use Conform.

## Validation Procedure

### Static review

Confirm that:

- `stevearc/conform.nvim` is declared exactly once;
- the old global `BufWritePre` formatting callback is removed;
- the Rust-specific formatting callback is removed;
- no new duplicate save-format autocmd is introduced;
- Biome has `require_cwd = true`;
- LSP fallback remains enabled;
- no unrelated files are modified.

### Install and startup validation

Run inside Neovim:

```vim
:PackerSync
```

Restart Neovim and run:

```vim
:ConformInfo
```

Confirm that Conform loads without Lua errors.

### Formatter behavior tests

#### Biome project

1. Open a JavaScript or TypeScript file inside a project containing `biome.json` or `biome.jsonc`.
2. Run `:ConformInfo`.
3. Confirm `biome` is available and selected.
4. Save a deliberately misformatted file.
5. Confirm the file is formatted before the write completes.

#### Non-Biome web project

1. Open a JavaScript or TypeScript file in a project without a Biome configuration.
2. Run `:ConformInfo`.
3. Confirm Biome is not selected.
4. Confirm an attached LSP formatter is used when available.
5. Confirm saving does not display a missing-Biome error.

#### Go

1. Open a `.go` file.
2. Confirm `goimports` is used when installed.
3. Temporarily test without `goimports`, if practical, and confirm `gofmt` is used.
4. Verify imports and formatting are applied on save.

#### Python

1. Open a Python file with Black installed.
2. Save a misformatted file.
3. Confirm Black formatting is applied.

#### Rust

1. Open a Rust file.
2. Save it once.
3. Confirm formatting runs once, with no duplicate edits or repeated notifications.

#### Lua

1. Open a Lua file with StyLua installed.
2. Confirm formatting works through Conform.

#### Manual formatting

1. Modify a supported file without saving.
2. Press `<leader>cf`.
3. Confirm the buffer formats successfully.

## Useful Commands

```vim
:ConformInfo
:PackerSync
:checkhealth
```

From the shell, confirm formatter availability as needed:

```sh
biome --version
goimports -h
gofmt -h
black --version
rustfmt --version
stylua --version
```

For JavaScript projects, Conform can resolve a project-local Biome binary from `node_modules`, so a global Biome installation should not be required when the project already declares it.

## Acceptance Criteria

The task is complete when all of the following are true:

- Conform is installed and loaded through Packer.
- Saving a buffer uses one formatting path only.
- Save-time formatting completes before the file write.
- Biome is used only in projects with a recognized Biome config.
- Web projects without Biome continue to use LSP formatting when available.
- Go, Python, Rust, and Lua retain explicit formatter support.
- Unsupported filetypes can still use LSP formatting.
- `<leader>cf` manually formats the active buffer.
- `:ConformInfo` reports the expected formatter for each tested filetype.
- No plugin-manager migration or unrelated configuration cleanup is included.

## Scope Guardrails

Do not:

- migrate from Packer to Lazy, pckr, or another plugin manager;
- remove or replace existing LSP servers;
- enable Biome lint fixes or `biome check` unless explicitly requested later;
- add Mason formatter installation automation;
- reformat unrelated Lua files;
- modify themes, completion, Telescope, terminal, AI, or Git integrations;
- merge or push unrelated local changes.
