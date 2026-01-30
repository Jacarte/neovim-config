vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

require('options')
require('keymaps')
require('commands')
require('plugins')
require('themes')  -- Theme at the end, to prevent overwrite by other plugins

-- Disabled: Auto-change to file's directory (conflicts with project.nvim)
-- vim.api.nvim_create_autocmd("BufEnter", {
--   pattern = "*",
--   callback = function()
--     local buftype = vim.api.nvim_buf_get_option(0, 'buftype')
--     -- Skip temp/special buffers to prevent directory jumping
--     if buftype == '' or buftype == 'acwrite' then
--       local bufname = vim.api.nvim_buf_get_name(0)
--       local is_temp = bufname:match('://') or bufname:match('^fugitive://')
--       if bufname ~= '' and not is_temp then
--         local bufdir = vim.fn.expand('%:p:h')
--         if bufdir ~= '' and vim.fn.isdirectory(bufdir) == 1 then
--           vim.cmd('silent! lcd ' .. vim.fn.fnameescape(bufdir))
--         end
--       end
--     end
--   end
-- })

-- Auto-reload config when nvim config files are saved
vim.cmd([[
  augroup nvim_config_auto_reload
    autocmd!
    autocmd BufWritePost ~/.config/nvim/init.lua source $MYVIMRC
    autocmd BufWritePost ~/.config/nvim/lua/*.lua source $MYVIMRC
    autocmd BufWritePost ~/.config/nvim/lua/*/*.lua source $MYVIMRC
    autocmd BufWritePost ~/.config/nvim/lua/*/*/*.lua source $MYVIMRC
  augroup END
]])

-- Auto format

vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = "*",
  callback = function()
    vim.lsp.buf.format({ async = true })
  end
})

