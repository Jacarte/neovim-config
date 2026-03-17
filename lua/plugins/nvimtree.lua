-- NVIM tree

local api = require('nvim-tree.api')

require('nvim-tree').setup({
  disable_netrw = false,
  hijack_netrw = false,
  update_cwd = false,

  system_open = {
     cmd = "open",
  },
  hijack_directories = {
    enable = true,
    auto_open = true,
  },
  update_focused_file = {
    enable = true,
    update_cwd = false,
  },
  filters = {
    enable = true,
    custom = { "^\\.git$" },
  },
  live_filter = {
    always_show_folders = false,
  },
  actions = {
    open_file = {
      quit_on_open = true,
    },
  },
  view = {
    side = "right",
    width = 40,
  },
  on_attach = function(bufnr)
    api.config.mappings.default_on_attach(bufnr)
    vim.keymap.set('n', 'u', api.tree.change_root_to_parent, { buffer = bufnr })
    vim.keymap.set('n', 'L', api.tree.expand_all, { buffer = bufnr })
    vim.keymap.set('n', 'E', '<CMD>NvimTreeToggle<CR>', { buffer = bufnr })
  end,
})
