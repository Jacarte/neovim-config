local utils = require('lsp.utils')
local common_on_attach = utils.common_on_attach

local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities = require('cmp_nvim_lsp').default_capabilities(capabilities)

vim.lsp.config('ts_ls', {
  capabilities = capabilities,
  on_attach = function(client, bufnr)
    client.server_capabilities.documentFormattingProvider = true
    client.server_capabilities.documentRangeFormattingProvider = true
    common_on_attach(client, bufnr)
  end,
  root_markers = { "tsconfig.json", "package.json", ".git" },
  filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact", "vue" },
  cmd = { "typescript-language-server", "--stdio" },
})
vim.lsp.enable('ts_ls')

local base_on_attach = vim.lsp.config.eslint.on_attach
local eslint_fix_all_group = vim.api.nvim_create_augroup('eslint_fix_all_on_save', { clear = false })
vim.lsp.config('eslint', {
  capabilities = capabilities,
  on_attach = function(client, bufnr)
    vim.api.nvim_clear_autocmds({ group = eslint_fix_all_group, buffer = bufnr })
    if base_on_attach then
      base_on_attach(client, bufnr)
      if vim.api.nvim_buf_get_commands(bufnr, {}).LspEslintFixAll then
        vim.api.nvim_create_autocmd("BufWritePre", {
          group = eslint_fix_all_group,
          buffer = bufnr,
          command = "LspEslintFixAll"
        })
      end
    end
    common_on_attach(client, bufnr)
  end,
  root_markers = { ".eslintrc", ".eslintrc.js", ".eslintrc.json", "package.json", ".git" },
})
vim.lsp.enable('eslint')
