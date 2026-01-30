-- Define commands

-- Remove trailing whitespaces
-- (if a file requires trailing spaces, exclude its type using the regex)
vim.cmd [[autocmd BufWritePre * %s/\s\+$//e ]]

-- Swap folder
vim.cmd('command! ListSwap split | enew | r !ls -l ~/.local/share/nvim/swap')
vim.cmd('command! CleanSwap !rm -rf ~/.local/share/nvim/swap/')

-- Open help tags
vim.cmd("command! HelpTags Telescope help_tags")

-- Create ctags
vim.cmd('command! MakeCTags !ctags -R --exclude=@.ctagsignore .')

-- Debug neotest with current file
vim.cmd('command! NeotestFile lua require("neotest").run.run(vim.fn.expand("%")); vim.defer_fn(function() require("neotest").summary.open() end, 500)')

-- Debug neotest
vim.cmd('command! NetotestDebug lua require("neotest")._debug()')
