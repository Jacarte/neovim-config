vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

require('options')
require('keymaps')
require('commands')
require('plugins')
require('themes')  -- Theme at the end, to prevent overwrite by other plugins

vim.api.nvim_create_autocmd("BufEnter", {
  pattern = "*",
  callback = function()
    local buftype = vim.api.nvim_buf_get_option(0, 'buftype')
    if buftype == '' or buftype == 'acwrite' then
      local bufdir = vim.fn.expand('%:p:h')
      if bufdir ~= '' and vim.fn.isdirectory(bufdir) == 1 then
        vim.cmd('silent! lcd ' .. vim.fn.fnameescape(bufdir))
      end
    end
  end
})

-- Auto format

vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = "*",
  callback = function()
    vim.lsp.buf.format({ async = true })
  end
})

