-- Plugin definition and loading
-- local execute = vim.api.nvim_command
local fn = vim.fn
local cmd = vim.cmd

-- Boostrap Packer
local install_path = fn.stdpath('data')..'/site/pack/packer/opt/packer.nvim'
local packer_bootstrap
if fn.empty(fn.glob(install_path)) > 0 then
  packer_bootstrap = fn.system({'git', 'clone','https://github.com/wbthomason/packer.nvim', install_path})
end

-- Load Packer
cmd([[packadd packer.nvim]])

-- Rerun PackerCompile everytime pluggins.lua is updated
cmd([[
  augroup packer_user_config
    autocmd!
    autocmd BufWritePost plugins.lua source <afile> | PackerCompile
  augroup end
]])

--cmd([[
-- packadd vimspector
-- let g:vimspector_sidebar_width = 85
-- let g:vimspector_bottombar_height = 15
-- let g:vimspector_terminal_maxwidth = 70
--]])
--vim.--  debuggers()
-- Initialize pluggins
return require('packer').startup(function(use)
  -- Let Packer manage itself
  use({'wbthomason/packer.nvim', opt = true})

 -- lsp status

  use('nvim-lua/lsp-status.nvim')
  -- Rust tools
  use("simrat39/rust-tools.nvim")
  -- LSP server
  use {
    "williamboman/mason.nvim",
    run = ":MasonUpdate" -- :MasonUpdate updates registry contents
  }
  use ({
    "williamboman/mason-lspconfig.nvim",
    requires = {
        "williamboman/mason.nvim"

    },
    config = function() require('plugins.mason-lspconfig') end,
  })

  use({
    'neovim/nvim-lspconfig',
    config = function() require('plugins.lspconfig') end
  })

-- vimspector
-- use {
--  "puremourning/vimspector",
--  opt = true,
-- cmd = { "VimspectorInstall", "VimspectorUpdate" },
--  fn = { "vimspector#Launch()", "vimspector#ToggleBreakpoint", "vimspector#Continue" },
--  config = function()
--    require("plugins.vimspector").setup()
--  end,
--}

  -- Use mason instead
    -- Autocomplete
  use({
    "hrsh7th/nvim-cmp",
    -- Sources for nvim-cmp
    requires = {
      "hrsh7th/vim-vsnip",
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "hrsh7th/cmp-nvim-lua",
      "hrsh7th/cmp-cmdline",
      "saadparwaiz1/cmp_luasnip",
    },
    config = function() require('plugins.cmp') end,
  })

  -- Treesitter
  use({
    'nvim-treesitter/nvim-treesitter',
    config = function() require('plugins.treesitter') end,
    run = ':TSUpdate'
  })

  -- Snippets
  use {"L3MON4D3/LuaSnip", config = function() require('plugins.snippets') end}
  use "rafamadriz/friendly-snippets"

  -- Signature help
  use "ray-x/lsp_signature.nvim"

  -- Telescope
  use({
    'nvim-telescope/telescope.nvim',
    requires = {{'nvim-lua/plenary.nvim'}},
    config = function() require('plugins.telescope') end,
  })

  use({'nvim-telescope/telescope-fzf-native.nvim', run ='make'})

  -- bufferline
  use({
    'akinsho/bufferline.nvim',
    requires = 'kyazdani42/nvim-web-devicons',
    config = function() require('plugins.bufferline') end,
    event = 'BufWinEnter',
  })

  -- statusline
  use({
    'hoob3rt/lualine.nvim',
    config = function() require('plugins.lualine') end,
  })

  -- NvimTree
  use({
    'nvim-tree/nvim-tree.lua',
    requires = {
      'nvim-tree/nvim-web-devicons', -- optional, for file icons
    },
    config = function() require('plugins.nvimtree') end,  -- Must add this manually
  })

  -- Startify
  use({
    'mhinz/vim-startify',
    config = function()
      local path = vim.fn.stdpath('config')..'/lua/plugins/startify.vim'
      vim.cmd('source '..path)
    end
  })

  -- git commands
  use 'tpope/vim-fugitive'

  -- Gitsigns
  use ({
    'lewis6991/gitsigns.nvim',
    requires = {'nvim-lua/plenary.nvim'},
    config = function() require('plugins.gitsigns') end
  })

  -- copilot
  use({'github/copilot.vim',
      config = function() require('plugins.copilot') end
    })

  -- Formatting
  use 'tpope/vim-commentary'
  use 'tpope/vim-unimpaired'
  use 'tpope/vim-surround'
  use 'tpope/vim-repeat'
  use 'junegunn/vim-easy-align'
  use 'voldikss/vim-floaterm'

  -- Python formatting
  use "EgZvor/vim-black"
  use 'jeetsukumaran/vim-python-indent-black'

  -- Python
  -- use 'heavenshell/vim-pydocstring'   -- Overwrites a keymap, need to fix.
  -- use 'bfredl/nvim-ipy'

  -- Markdown
  use 'godlygeek/tabular'
  use 'ellisonleao/glow.nvim'

  -- floating terminals
  use 'kassio/neoterm'
  -- Rust LSP
  -- use 'neoclide/coc.nvim'

  -- use "neovim/nvim-lspconfig"

  -- TOML Files
  use 'cespare/vim-toml'

  -- Poetry
  -- use({'petobens/poet-v',
  --   config = function()
  --     local path = vim.fn.stdpath('config')..'/lua/plugins/poet-v.vim'
  --     vim.cmd('source '..path)
  --   end
  -- })

  -- kitty config syntax-highlight
  use "fladson/vim-kitty"

  -- note taking with zettelkasten

  -- Themes
  use 'folke/tokyonight.nvim'
  use 'marko-cerovac/material.nvim'

  use({
  "jackMort/ChatGPT.nvim",
    config = function()
      require("chatgpt").setup({
        -- optional configuration
      })
    end,
    requires = {
      "MunifTanjim/nui.nvim",
      "nvim-lua/plenary.nvim",
      "nvim-telescope/telescope.nvim"
    }
})

  use { 'justinhj/battery.nvim', requires = {{'kyazdani42/nvim-web-devicons'}, {'nvim-lua/plenary.nvim'}},
    config = function() require('plugins.battery') end
  }

  if packer_bootstrap then
    require('packer').sync()
  end


  function sizer(term)
    if term.direction == "horizontal" then
      return 15
    elseif term.direction == "vertical" then
      return vim.o.colums * 0.4
    end

    return 20
  end

  use {"akinsho/toggleterm.nvim", tag = '*', config = function()
    require("toggleterm").setup{
      shade_filetypes = {},
      size = sizer
    }
    require("plugins.toggleterm")
  end}


  -- rooter
  -- SO we do not change to opened file location for telescope
  use {
    "ahmedkhalf/project.nvim",
    config = function() require("plugins.project_nvim") end
  }

  use "elihunter173/dirbuf.nvim"
  -- dotenv
  use { "ellisonleao/dotenv.nvim", config = function() require("plugins.dotenv") end }
end)
