local M = {}

function M.setup()
  local conform = require("conform")

  conform.setup({
    formatters_by_ft = {
      lua = { "stylua" },
      python = { "black" },
      go = { "goimports", "gofmt", stop_after_first = true },
      rust = { "rustfmt" },
      javascript = { "biome" },
      javascriptreact = { "biome" },
      typescript = { "biome" },
      typescriptreact = { "biome" },
      json = { "biome" },
      jsonc = { "biome" },
      css = { "biome" },
      graphql = { "biome" },
    },
    default_format_opts = {
      lsp_format = "fallback",
    },
    format_on_save = {
      timeout_ms = 1000,
      lsp_format = "fallback",
    },
    formatters = {
      biome = {
        -- Use Biome only in projects that explicitly configure it.
        -- Otherwise Conform falls back to the attached LSP formatter.
        require_cwd = true,
      },
    },
    notify_no_formatters = false,
  })

  vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"

  vim.keymap.set("n", "<leader>cf", function()
    conform.format({
      async = true,
      lsp_format = "fallback",
    })
  end, { desc = "Format buffer" })
end

return M
