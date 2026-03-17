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
  use({
    'mrcjkb/rustaceanvim',
    ft = { 'rust' },
    tag = '5.15.1',
  })
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

  use {
    "nvim-neotest/neotest",
    requires = {
      "nvim-neotest/nvim-nio",
      "nvim-lua/plenary.nvim",
      "antoinemadec/FixCursorHold.nvim",
      "nvim-treesitter/nvim-treesitter",
      'nvim-neotest/neotest-go',
    },
     config = function()
       -- get neotest namespace (api call creates or returns namespace)
     local neotest_ns = vim.api.nvim_create_namespace("neotest")
     vim.diagnostic.config({
       virtual_text = {
         format = function(diagnostic)
           local message =
             diagnostic.message:gsub("\n", " "):gsub("\t", " "):gsub("%s+", " "):gsub("^%s+", "")
           return message
         end,
       },
     }, neotest_ns)
        local neotest = require('neotest')
        neotest.setup({
          adapters = {
            require('neotest-go')({
              args = { '-coverprofile=coverage.out' },
              experimental = {
                test_table = true
              },
            })
          },
          icons = {
            child_indent = "│",
            child_prefix = "├",
            collapsed = "─",
            expanded = "╮",
            failed = "✖",
            final_child_indent = " ",
            final_child_prefix = "└",
            non_collapsible = "─",
            passed = "✓",
            running = "🏃",
            running_animated = { "🏃", "🏃" },
            skipped = "⊘",
            unknown = "?"
          },
          diagnostic = {
            enabled = true,
          },
          status = {
            enabled = true,
            signs = true,
            virtual_text = true,
          },
        })

        -- Log when tests are run
        local original_run = neotest.run.run
        neotest.run.run = function(...)
          local file = vim.fn.expand("%:p")
          local cwd = vim.fn.getcwd()
          vim.notify("Neotest - File: " .. file .. " | CWD: " .. cwd, vim.log.levels.INFO)
          return original_run(...)
        end
     end,
  }

   use{
	'andythigpen/nvim-coverage',
    dependencies = {
        'nvim-lua/plenary.nvim',
    },
    config = function()
        require('coverage').setup({
          auto_reload = true,
          lang = {
            go = {
              -- We need this because we have hardcoded the cwd to be the project/repo root folder
              -- to make telescope to work globally
              coverage_file = function()
                local f = vim.api.nvim_buf_get_name(0)
                local dir = vim.fs.dirname(f)
                local path = dir .. "/coverage.out"
                vim.notify("nvim-coverage: using " .. path)
                return path
              end
            }
          }
        })
    end,
  }

  use{
    'nvim-treesitter/nvim-treesitter', tag = 'v0.9.3',
    config = function()
      require('nvim-treesitter.configs').setup({
        ensure_installed = { 'go', 'lua', 'typescript', 'javascript', 'json', 'yaml', 'html', 'css', 'bash', 'python', 'markdown', 'scala' },
        highlight = {
          enable = true,
        },
      })
    end
  }
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
  --use({
  --  'nvim-treesitter/nvim-treesitter',
  --  config = function() require('plugins.treesitter') end,
  --  run = ':TSUpdate'
  --})

  -- Snippets
  use {"L3MON4D3/LuaSnip", config = function() require('plugins.snippets') end}
  use "rafamadriz/friendly-snippets"

  -- Signature help
  use "ray-x/lsp_signature.nvim"

  use({'nvim-telescope/telescope-fzf-native.nvim', run ='cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release && cmake --build build --config Release && cmake --install build --prefix build'})
  -- Telescope
  use({
    'nvim-telescope/telescope.nvim',
    requires = {
      {'nvim-lua/plenary.nvim'},
      {'nvim-telescope/telescope-fzy-native.nvim'}
    },
    config = function() require('plugins.telescope') end,
  })


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
  --

  -- oil.nvim
  --require("packer").startup(function()
   -- use({
   --   "stevearc/oil.nvim",
   --   config = function()
   --     require("oil").setup({
   --       use_default_keymaps = true,
   --     })
   --   end,
  --  })
  --end)

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

  -- copilot (LSP-based for Sidekick integration)
  use({
    'zbirenbaum/copilot.lua',
    cmd = "Copilot",
    event = "InsertEnter",
    config = function()
      require('copilot').setup({
        suggestion = { enabled = false },  -- Sidekick handles this via NES
        panel = { enabled = true },
        copilot_node_command = 'node',
      })
    end
  })

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

  --use({
  --"jackMort/ChatGPT.nvim",
  --  config = function()
  --    require("chatgpt").setup({
  --      -- optional configuration
  --    })
  --  end,
  --  requires = {
  --    "MunifTanjim/nui.nvim",
  --    "nvim-lua/plenary.nvim",
  --    "nvim-telescope/telescope.nvim"
  --  }
--})

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

  -- dotenv
  use { "ellisonleao/dotenv.nvim", config = function() require("plugins.dotenv") end }

  -- harpoon
  use {
    "ThePrimeagen/harpoon",
    branch = "harpoon2",
    requires = { "nvim-lua/plenary.nvim" }
  }

  -- sidekick for AI helper
  --use {
  -- "folke/sidekick.nvim",
  --  requires = {
  --      "nvim-lua/plenary.nvim",
  -- },
  --  config = function()
  --    require("plugins.sidekick")
  --  end
  -- }

  use {
    "nickjvandyke/opencode.nvim",
    version = "*", -- Latest stable release
    run = function(plugin)
      require("plugins.opencode_patch").apply(plugin.install_path)
    end,
    requires = {
      {
        -- `snacks.nvim` integration is recommended, but optional
        ---@module "snacks" <- Loads `snacks.nvim` types for configuration intellisense
        "folke/snacks.nvim",
        config = function()
          require("snacks").setup({
            input = { enabled = true }, -- Enhances `ask()`
            picker = { -- Enhances `select()`
              actions = {
                opencode_send = function(...) return require("opencode").snacks_picker_send(...) end,
              },
              win = {
                input = {
                  keys = {
                    ["<a-a>"] = { "opencode_send", mode = { "n", "i" } },
                  },
                },
              },
            },
          })
        end,
      },
    },
    config = function() require("plugins.opencode") end,
  }

  -- trouble
  use {
    "folke/trouble.nvim"
  }

end)
