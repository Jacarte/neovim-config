local utils = require('lsp.utils')
local common_on_attach = utils.common_on_attach

-- add capabilities from nvim-cmp
local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities = require('cmp_nvim_lsp').default_capabilities(capabilities)

-- Enable language servers with common settings
local servers = {"bashls", "clangd", "pyright", "jsonls", "dockerls"}
for _, lsp in ipairs(servers) do
  vim.lsp.config[lsp] = {
    cmd = vim.lsp.config[lsp].cmd,
    filetypes = vim.lsp.config[lsp].filetypes,
    root_markers = vim.lsp.config[lsp].root_markers,
    on_attach = common_on_attach,
    capabilities = capabilities,
  }
end


vim.lsp.config["pyright"] = {
  cmd = vim.lsp.config["pyright"].cmd,
  filetypes = vim.lsp.config["pyright"].filetypes,
  root_markers = vim.lsp.config["pyright"].root_markers,
  capabilities = capabilities,
  on_attach = common_on_attach,
  settings={
      python = {
      pythonPath="/usr/bin/python3.9"
      },
      pyright = {}
  }
}

require('lsp.rust')
-- require('lsp.sumneko')

require('lsp.ts')

require("lsp.golang")

-- signature help hover
require "lsp_signature".setup({ })


