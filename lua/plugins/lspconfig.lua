local utils = require('lsp.utils')
local common_on_attach = utils.common_on_attach

local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities = require('cmp_nvim_lsp').default_capabilities(capabilities)

local simple_servers = { "bashls", "clangd", "jsonls", "dockerls" }
for _, name in ipairs(simple_servers) do
  vim.lsp.config(name, { on_attach = common_on_attach, capabilities = capabilities })
  vim.lsp.enable(name)
end

vim.lsp.config('pyright', {
  on_attach = common_on_attach,
  capabilities = capabilities,
  settings = {
    python = { pythonPath = "/usr/bin/python3.9" },
    pyright = {}
  }
})
vim.lsp.enable('pyright')

require('lsp.rust')
-- require('lsp.sumneko')

require('lsp.ts')
require('lsp.golang')

require("lsp_signature").setup({})

vim.lsp.enable("copilot")
