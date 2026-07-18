require("mason").setup()
require("mason-lspconfig").setup {
    ensure_installed = {
      "bashls",
      "clangd",
      "jsonls",
      -- Rust implemented is always better than node :|
      "pyright",
      -- "julials",
       "rust_analyzer",
      -- "sumneko_lua",
       "texlab",
       "ts_ls",
       -- go
       "gopls"
     },
    automatic_enable = {
      exclude = { "pylyzer" },
    },
    automatic_installation= true,
}
