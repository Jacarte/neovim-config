require('bufferline')

-- format as "<id>. <file-name>"
local tabname_format = function (opts)
  return string.format('%s.', opts.ordinal)
end

require('bufferline').setup({
  options = {
    always_show_bufferline = true,
    numbers = tabname_format,
    show_buffer_icons = true,
    show_buffer_close_icons = false,
    show_close_icon = false,
    separator_style = 'slant',
    custom_filter = function(bufnr)
      local ft = vim.bo[bufnr].filetype
      local bt = vim.bo[bufnr].buftype
      return ft ~= 'NvimTree' and bt ~= 'terminal'
    end,
    -- Don't show bufferline over vertical, unmodifiable buffers
    offsets = {{
        filetype = 'NvimTree',
        text = 'File Explorer',
        highlight = 'Directory',
        separator = true,
    }},
  },
  -- Don't use italic on current buffer
  highlights = {buffer_selected = { bold = true },},
})
