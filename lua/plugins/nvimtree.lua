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
    -- adaptive_size = false,
    mappings = {
      list = {
        { key = "u", action= "dir_up" }
      }
    }
  }
})
