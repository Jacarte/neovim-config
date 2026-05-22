local harpoon = require("harpoon")

harpoon:setup({
  default = {
    equals = function(list_item_a, list_item_b)
      if list_item_a == nil and list_item_b == nil then return true end
      if list_item_a == nil or list_item_b == nil then return false end
      return list_item_a.value == list_item_b.value
        and list_item_a.context.row == list_item_b.context.row
        and list_item_a.context.col == list_item_b.context.col
    end,
    display = function(list_item)
      local filename = vim.fn.fnamemodify(list_item.value, ":t")
      return filename .. ":" .. (list_item.context.row or "?") .. ":" .. (list_item.context.col or "?")
    end,
    -- Always restore the saved position, even when the buffer is already loaded
    select = function(list_item, list, options)
      if list_item == nil then return end
      options = options or {}
      local bufnr = vim.fn.bufnr("^" .. list_item.value .. "$")
      if bufnr == -1 then bufnr = vim.fn.bufadd(list_item.value) end
      if not vim.api.nvim_buf_is_loaded(bufnr) then
        vim.fn.bufload(bufnr)
        vim.api.nvim_set_option_value("buflisted", true, { buf = bufnr })
      end
      if options.vsplit then vim.cmd("vsplit")
      elseif options.split then vim.cmd("split")
      elseif options.tabedit then vim.cmd("tabedit")
      end
      vim.api.nvim_set_current_buf(bufnr)
      local row = math.min(list_item.context.row or 1, vim.api.nvim_buf_line_count(bufnr))
      local row_text = vim.api.nvim_buf_get_lines(0, row - 1, row, false)
      local col = math.min(list_item.context.col or 0, row_text[1] and #row_text[1] or 0)
      vim.api.nvim_win_set_cursor(0, { row, col })
    end,
    -- Disable BufLeave auto-update: with multiple same-file bookmarks,
    -- auto-updating by filename alone would corrupt the wrong entry.
    -- Positions are fixed snapshots captured at bookmark-add time.
    BufLeave = function(arg, list) end,
  }
})
