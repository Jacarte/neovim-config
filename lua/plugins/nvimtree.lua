-- NVIM tree

require('nvim-tree').setup({
  -- Allow using gx
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
    update_cwd = true,
  },
  view = {
    float = {
      enable = true,
      quit_on_focus_loss = true,
      open_win_config = {
        relative = "editor",
        border = "rounded",
        width = 100,
        height = 40,
        row = 1,
        col = 1,
      },
    },
    mappings = {
      list = {
        { key = "u", action= "dir_up" }
      }
    }
  }
})
