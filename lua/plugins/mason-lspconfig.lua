require("mason-lspconfig").setup {
    ensure_installed = {
      "bashls",
      "clangd",
      "jsonls",
      -- "julials",
      "pyright",
      "rust_analyzer",
      -- "sumneko_lua",
      "texlab",
    },
    automatic_installation= true,
}
