local nvim_lsp = require('lspconfig')
local utils = require('lsp.utils')
local common_on_attach = utils.common_on_attach

-- add capabilities from nvim-cmp
local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities = require('cmp_nvim_lsp').default_capabilities(capabilities)

-- Enable language servers with common settings
local servers = {"bashls", "clangd", "pyright", "jsonls", "dockerls"}
for _, lsp in ipairs(servers) do
  nvim_lsp[lsp].setup({
    on_attach = common_on_attach,
    capabilities = capabilities,
  })
end


nvim_lsp["pyright"].setup({
  capabilities = capabilities,
  on_attach = common_on_attach,
  settings={
      python = {
      pythonPath="/usr/bin/python3.9"
      },
      pyright = {}
  }
})

require('lsp.rust')
-- require('lsp.sumneko')

-- Go configuration
nvim_lsp.gopls.setup({
  capabilities = capabilities,
  on_attach = common_on_attach,
  cmd = { "gopls" },
  filetypes = { "go", "gomod", "gowork", "gotmpl" },
  root_dir = { "go.work", "go.mod", ".git"  },
  settings = {
    gopls = {
      completeUnimported = true,
      usePlaceholders = true,
      analyses = {
        unusedparams = true
      },
    },
  },
})

-- signature help hover
require "lsp_signature".setup({ })


