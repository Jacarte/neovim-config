local utils = require('lsp.utils')
local common_on_attach = utils.common_on_attach


-- add capabilities from nvim-cmp
local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities = require('cmp_nvim_lsp').default_capabilities(capabilities)

-- TypeScript/JavaScript via ts_ls (formerly tsserver)
vim.lsp.config.ts_ls = {
  cmd = { "typescript-language-server", "--stdio" },
  filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact", "vue" },
  root_markers = { "tsconfig.json", "package.json", ".git" },
  capabilities = capabilities,
  on_attach = function(client, bufnr)
    client.server_capabilities.documentFormattingProvider = false
    client.server_capabilities.documentRangeFormattingProvider = false
    common_on_attach(client, bufnr)
  end,
}

-- Optional: ESLint LSP for linting
vim.lsp.config.eslint = {
  cmd = vim.lsp.config.eslint.cmd,
  filetypes = vim.lsp.config.eslint.filetypes,
  root_markers = { ".eslintrc", ".eslintrc.js", ".eslintrc.json", "package.json", ".git" },
  capabilities = capabilities,
  on_attach = function(client, bufnr)
    vim.api.nvim_create_autocmd("BufWritePre", {
      buffer = bufnr,
      command = "EslintFixAll"
    })
    common_on_attach(client, bufnr)
  end,
}

