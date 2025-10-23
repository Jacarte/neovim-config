local utils = require('lsp.utils')
local common_on_attach = utils.common_on_attach
local capabilities = vim.lsp.protocol.make_client_capabilities()

capabilities.textDocument.semanticTokens = {
  dynamicRegistration = false,
  requests = {
    range = true,
    full = true,
  },
  tokenTypes = {
    "namespace", "type", "class", "enum", "interface", "struct",
    "typeParameter", "parameter", "variable", "property", "enumMember",
    "event", "function", "method", "macro", "keyword", "modifier",
    "comment", "string", "number", "regexp", "operator",
  },
  tokenModifiers = {
    "declaration", "definition", "readonly", "static", "deprecated",
    "abstract", "async", "modification", "documentation", "defaultLibrary"
  },
}

vim.api.nvim_set_hl(0, "@lsp.type.property", { link = "Identifier" })
vim.api.nvim_set_hl(0, "@lsp.type.variable", { link = "Identifier" })

-- Go configuration
vim.lsp.config.gopls = {
  cmd = { "gopls" },
  filetypes = { "go", "gomod", "gowork", "gotmpl" },
  root_markers = { "go.work", "go.mod", ".git" },
  capabilities = capabilities,
  on_attach = common_on_attach,
  settings = {
    gopls = {
      completeUnimported = true,
      usePlaceholders = false,
      analyses = {
        unusedparams = true
      },
    },
  },
}

