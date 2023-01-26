-- Lualine configuration

local non_language_ft = {'fugitive', 'startify'}

local nvimbattery = {
  function()
    return require("battery").get_status_line()
  end,
  color = { fg = 'ffffff', gui='bold' },
}

local lsp_status = require('lsp-status');
local lspconfig = require('lspconfig');

lsp_status.register_progress()

local function lsp()
    return require('lsp-status').status()
end

require('lualine').setup({
  options = {
    theme = "tokyonight",
    -- Separators might look weird for certain fonts (eg Cascadia)
    component_separators = {left = '', right = ''},
    section_separators = {left = '', right = ''},
    globalstatus = true,
  },
  sections = {
    lualine_a = {'mode'},
    lualine_b = {'branch', 'diff'},
    lualine_c = {
      'filetype',
      {
        function()
          local msg = 'No LSP'
          local buf_ft = vim.api.nvim_buf_get_option(0, 'filetype')
          local clients = vim.lsp.get_active_clients()

          if next(clients) == nil  then
            return msg
          end

          -- Check for utility buffers
          for ft in non_language_ft do
            if ft:match(buf_ft) then
              return ''
            end
          end

          for _, client in ipairs(clients) do
            local filetypes = client.config.filetypes

            if filetypes and vim.fn.index(filetypes, buf_ft) ~= -1 then
              -- return 'LSP:'..client.name  -- Return LSP name
              return ''  -- Only display if no LSP is found
            end
          end

          return msg
        end,
        color = {fg = '#ffffff', gui = 'bold'},
        separator = "",
      },
      {
        'diagnostics',
        sources = {'nvim_diagnostic'},
        sections = {'error', 'warn', 'info'},
      },
      lsp,
    },
    lualine_x = { nvimbattery, 'windows', 'tabs', 'encoding'},
    lualine_y = {'progress'},
    lualine_z = {
      {function () return '' end},
      {'location'},
    }
  },
})
