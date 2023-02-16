lua<<EOF
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

require('options')
require('keymaps')
require('commands')
require('plugins')
require('themes')  -- Theme at the end, to prevent overwrite by other plugins
EOF

autocmd BufEnter * silent! lcd %:p:h
