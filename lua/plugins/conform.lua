local M = {}

function M.setup()
  local conform = require('conform')

  conform.setup({
    formatters_by_ft = {
      javascript = { 'biome' },
      javascriptreact = { 'biome' },
      typescript = { 'biome' },
      typescriptreact = { 'biome' },
      json = { 'biome' },
      jsonc = { 'biome' },
      css = { 'biome' },
      graphql = { 'biome' },
      go = { 'goimports', 'gofmt', stop_after_first = true },
      python = { 'black' },
      rust = { 'rustfmt' },
      lua = { 'stylua' },
    },
    default_format_opts = {
      lsp_format = 'fallback',
    },
    format_on_save = {
      timeout_ms = 1000,
      lsp_format = 'fallback',
    },
    formatters = {
      biome = {
        -- Keep the built-in implementation; require one of its recognized project roots.
        require_cwd = true,
      },
    },
    notify_no_formatters = false,
  })

  vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"

  vim.keymap.set('n', '<leader>cf', function()
    conform.format({
      async = true,
      lsp_format = 'fallback',
    })
  end, { desc = 'Format buffer' })
end

return M
