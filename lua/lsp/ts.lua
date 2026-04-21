local nvim_lsp = require('lspconfig')
local utils = require('lsp.utils')
local common_on_attach = utils.common_on_attach

-- add capabilities from nvim-cmp
local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities = require('cmp_nvim_lsp').default_capabilities(capabilities)

-- TypeScript/JavaScript via tsserver
nvim_lsp.tsserver.setup({
  capabilities = capabilities,
  on_attach = function(client, bufnr)
    -- Disable tsserver formatting in favor of prettier or null-ls
    client.server_capabilities.documentFormattingProvider = true
    client.server_capabilities.documentRangeFormattingProvider = true
    common_on_attach(client, bufnr)
  end,
  root_dir = nvim_lsp.util.root_pattern("tsconfig.json", "package.json", ".git"),
  filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact", "vue" },
  cmd = { "typescript-language-server", "--stdio" },
})

-- Optional: ESLint LSP for linting
nvim_lsp.eslint.setup({
  capabilities = capabilities,
  on_attach = function(client, bufnr)
    -- You can enable auto-fix on save
    vim.api.nvim_create_autocmd("BufWritePre", {
      buffer = bufnr,
      command = "EslintFixAll"
    })
    common_on_attach(client, bufnr)
  end,
  root_dir = nvim_lsp.util.root_pattern(".eslintrc", ".eslintrc.js", ".eslintrc.json", "package.json", ".git"),
})

