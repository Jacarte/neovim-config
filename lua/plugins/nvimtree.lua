-- NVIM tree

require('nvim-tree').setup({
  -- Allow using gx
  disable_netrw = true,
  hijack_netrw = true,
  update_cwd = true,
  view = {
    adaptive_size = true,
    mappings = {
      list = {
        { key = "u", action= "dir_up" }
      }
    }
  }
})
