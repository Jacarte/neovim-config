local actions = require('telescope.actions')
-- local utils = require('telescope.utils')
-- local trouble = require('telescope.providers.telescope')
local transform_mod = require('telescope.actions.mt').transform_mod


local mod = {}
mod.open_in_nvim_tree = function(prompt_bufnr)
    local cur_win = vim.api.nvim_get_current_win()
    vim.cmd("NvimTreeFindFile")
    vim.api.nvim_set_current_win(cur_win)
end

mod.cwd_up = function(prompt_bufnr)
    local state = require('telescope.actions.state')
    local picker = state.get_current_picker(prompt_bufnr)
    local cwd = picker.cwd or vim.fn.getcwd(-1, -1)
    local parent = vim.fn.fnamemodify(cwd, ':h')
    local nvim_root = vim.fn.getcwd(-1, -1)

    if parent ~= cwd and #parent >= #nvim_root then
        actions.close(prompt_bufnr)
        vim.notify("Telescope: " .. parent, vim.log.levels.INFO)
        require('telescope.builtin').find_files({
            cwd = parent,
            prompt_title = parent
        })
    else
        vim.notify("Already at nvim root", vim.log.levels.WARN)
    end
end

mod = transform_mod(mod)


require('telescope').setup({
  defaults = {
    sorting_strategy = "ascending",
    prompt_prefix = "🔍 ",
    path_display = { "truncate" },
    dynamic_preview_title = true,
    mappings = {
      i = {
        ['<C-j>'] = actions.move_selection_next,
        ['<C-k>'] = actions.move_selection_previous,
        ['<C-c>'] = actions.close,
        ['<C-u>'] = mod.cwd_up,
        ["<CR>"]  = actions.select_default,
      },
      n = {
        ['<C-c>'] = actions.close,
        ['<C-u>'] = mod.cwd_up,
        ["<CR>"]  = actions.select_default + mod.open_in_nvim_tree,
      },
    },
    layout_config = {
      horizontal ={
        height = 47,
        prompt_position = "top",
      }
    },
    borderchars = { "─", "│", "─", "│", "┌", "┐", "┘", "└" },
    results_title = false
  },

  extensions ={
      fzf = {
        fuzzy = true,
        override_generic_sorter = true,
        override_file_sorter = true,
        case_mode = "smart_case",
      },
      fzy_native = {
            override_generic_sorter = false,
            override_file_sorter = true,
        }
    },
})

require('telescope').load_extension('fzf')
require('telescope').load_extension('fzy_native')
