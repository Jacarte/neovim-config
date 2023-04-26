require("mason").setup()
require("mason-lspconfig").setup {
    ensure_installed = {
      "bashls",
      "clangd",
      "jsonls",
      -- Rust implemented is always better than node :|
      "pylyzer",
      -- "julials",
      -- "pyright",
       "rust_analyzer",
      -- "sumneko_lua",
       "texlab",
       "tsserver"
    },
    automatic_installation= true,
}
