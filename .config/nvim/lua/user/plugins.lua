local fn = vim.fn
local letg = vim.g
local keymap = vim.keymap.set

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

keymap("n", "<F1>", "<CMD>Lazy<CR>", { desc = "Lazy" })

return require("lazy").setup({
  "lewis6991/impatient.nvim",
  -- Git
  "tpope/vim-git",
  "tpope/vim-fugitive",
  {
    "lewis6991/gitsigns.nvim",
    config = function()
      require("gitsigns").setup()
    end,
  },
  -- Movement
  --  use ({"unblevable/quick-scope",  -- color next match for f,F,t,T
  --    setup = [[vim.g.qs_highlight_on_keys = {'f', 'F', 't', 'T'}]]
  --  })
  -- quick-scope in lua
  {
    "jinh0/eyeliner.nvim",          -- f/F gives indicator on line where to jump
    config = function()
      require("eyeliner").setup({
        highlight_on_key = true,
      })
      vim.api.nvim_create_autocmd("ColorScheme", {
        pattern = "*",
        callback = function()
          vim.api.nvim_set_hl(0, "EyelinerPrimary", { bold = true, underline = true })
        end,
      })
    end,
  },
  "ap/vim-you-keep-using-that-word",    -- disables cw/cW exception of not including the space(s, after word
  -- Sessions
  "tpope/vim-obsession",                -- continuously update session file
  {
    "dhruvasagar/vim-prosession",       -- handle and switch between sessions
    dependencies = "tpope/vim-obsession",
  },
  "907th/vim-auto-save",
  "simnalamburt/vim-mundo",     -- undo enhanced, f6
  "moll/vim-bbye",              -- closing buffers will not remove windows
  -- Programming
  "nvim-lua/plenary.nvim",      -- library of common lua functions
  "nvim-lua/popup.nvim",        -- utility package for popups
  {
    "neovim/nvim-lspconfig",    -- Quickstart configs for Nvim LSP 
    event = { 'BufReadPost', 'BufNewFile' },
    config = function()
      require("mason").setup()
      require("mason-lspconfig").setup()
    end,
  },
  "onsails/lspkind.nvim",       -- icons/pictograms for LSP
  {
    "williamboman/mason.nvim",  -- package manager for LSPs, DAP, linters, formatters
    config = function()
      require("mason").setup()
      keymap("n", "<F2>", "<CMD>Mason<CR>", { desc = "Mason" })
      require("mason.settings").set({
        ui = {
                  border = "rounded",
                  package_installed = "✓",
                },
        -- log_level = vim.log.levels.DEBUG
      })
    end,
  },
  {
    "williamboman/mason-lspconfig.nvim", -- bridges lspconfig + mason: sets up lsp-servers
    config = function()
      require("mason-lspconfig").setup({
        ensure_installed = {
          "rust_analyzer",
          "bashls",
          "pyright",
          "cssls",
          "gopls",
          "html",
          "jsonls", -- language servers
          "tsserver",
          "jsonnet_ls",
          "zk@v0.10.1",
          "taplo",
          "terraformls",
          "tflint",
          "vuels",
          "yamlls",
          "eslint",
        },
      })
    end,
  },
  -- {
  --   "glepnir/lspsaga.nvim",
  --   branch = "main",
  --   dependencies = {
  --     "kyazdani42/nvim-web-devicons",
  --     "nvim-treesitter/nvim-treesitter"
  --   },
  --   config = function()
  --     require('lspsaga').setup({})
  --   end,
  -- },
  {
    "VonHeikemen/lsp-zero.nvim",
    dependencies = {
      { "neovim/nvim-lspconfig" },
      -- {'williamboman/nvim-lsp-installer'},
      -- autocomp
      { "hrsh7th/nvim-cmp" },
      { "hrsh7th/cmp-buffer" },
      { "hrsh7th/cmp-path" },
      { "hrsh7th/cmp-nvim-lsp" },
      { "hrsh7th/cmp-nvim-lua" },
      -- snips
      { "saadparwaiz1/cmp_luasnip" },
      { "L3MON4D3/LuaSnip" },
      { "rafamadriz/friendly-snippets" },
    },
    config = function()
      local lsp = require("lsp-zero")
      lsp.preset("recommended")
      lsp.setup()
    end,
  },
  {"folke/trouble.nvim",
    dependencies = "kyazdani42/nvim-web-devicons",
    config = function()
      require("trouble").setup {
        mode = "document_diagnostics",
      }
    end
  }, -- show list of issues
  -- {
  --   "folke/noice.nvim",
  --   event = "VeryLazy",
  --   config = function()
  --     require("noice").setup({
  --       lsp = {
  --         override = {
  --           ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
  --           ["vim.lsp.util.stylize_markdown"] = true,
  --           ["cmp.entry.get_documentation"] = true,
  --         },
  --       },
  --       presets = {
  --         bottom_search = true, -- use a classic bottom cmdline for search
  --         command_palette = true, -- position the cmdline and popupmenu together
  --         long_message_to_split = true, -- long messages will be sent to a split
  --         inc_rename = false, -- enables an input dialog for inc-rename.nvim
  --         lsp_doc_border = false, -- add a border to hover docs and signature help  
  --       },
  --       routes = {
  --         {
  --           filter = {
  --             event = "mini",
  --             kind = "",
  --             find = "null-ls",
  --           },
  --           opts = { skip = true },
  --         }
  --       },
  --     })
  --   end,
  --   dependencies = {
  --     "MunifTanjim/nui.nvim",
  --     "rcarriga/nvim-notify",
  --   }
  -- },
  {"lukas-reineke/indent-blankline.nvim", main = "ibl", opts = {}},
  {
    "nvim-treesitter/nvim-treesitter",
    dependencies = {
      "nvim-treesitter/nvim-treesitter-textobjects",
      "nvim-treesitter/nvim-treesitter-refactor",
      "JoosepAlviste/nvim-ts-context-commentstring",
    },
  },
  -- {
  --  "nvimtools/none-ls.nvim", -- none-ls Use external formatters and linters
  --  dependencies = {
  --    "nvim-lua/plenary.nvim",
  --  },
  -- },
  -- Completion
  {
    "hrsh7th/nvim-cmp",
    event = "InsertEnter",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-path",
      {
        "L3MON4D3/LuaSnip",
        version = "2.*",
        build = "make install_jsregexp",
      },
      "hrsh7th/cmp-nvim-lua",
      "saadparwaiz1/cmp_luasnip",
      "rafamadriz/friendly-snippets",
      "hrsh7th/cmp-buffer",
      "onsails/lspkind.nvim",       -- icons/pictograms for LSP
      "hrsh7th/cmp-path",
      "petertriho/cmp-git",
      "hrsh7th/cmp-nvim-lsp-signature-help",
    },
  },
  {
    "Exafunction/codeium.nvim",
    dependencies = {
        "nvim-lua/plenary.nvim",
        "hrsh7th/nvim-cmp",
    },
    config = function()
        require("codeium").setup({
        })
    end
    },
    {
      "supermaven-inc/supermaven-nvim",
      config = function()
        require("supermaven-nvim").setup({
          keymaps = {
            accept_suggestion = "<CR>",
          --   clear_suggestion = "<C-]>",
          --   accept_word = "<C-j>",
          },
          disable_inline_completion = true,
          disable_keymaps = true,
        })
      end,
    },
    {
      "pasky/claude.vim",
      config = function()
        vim.g.claude_api_key = io.open(vim.fn.expand("~/.config/tokens/claude.token"), "r"):read("*l")
      end
    },
    {
      "robitx/gp.nvim",
      config = function()
        local conf = {
            -- For customization, refer to Install > Configuration in the Documentation/Readme
        }
        require("gp").setup(conf)

        -- Setup shortcuts here (see Usage > Shortcuts in the Documentation/Readme)
      end,
    },
  -- Formatting
    {
    'stevearc/conform.nvim',
    opts = {},
    config = function()
      require("conform").setup({
        formatters_by_ft = {
          lua = { "stylua" },
          -- Conform will run multiple formatters sequentially
          python = { "isort", "black" },
          html = { "prettier" },
          markdown = { "prettier" },
          css = { "prettier" },
          json = { "prettier" },
          yaml = { "prettier" },
          -- Use a sub-list to run only the first available formatter
          javascript = { { "prettierd", "prettier" } },
        },
      })
    end,
  },
  -- Fuzzy search
  {
    "nvim-telescope/telescope.nvim",
    dependencies = {},
  },
  -- misc
  {
    "tris203/precognition.nvim",
    event = "VeryLazy",
    config = function()
      require("precognition").setup({
        startVisible = false,
      })
      keymap("n", "<F3>", "<CMD>Precognition toggle<CR>", { desc = "Precognition toggle" })
    end,
  },
  {
    "echasnovski/mini.nvim",
    config = function()
      require('mini.ai').setup()
      require('mini.cursorword').setup()
      require('mini.extra').setup()
      require('mini.surround').setup()
      keymap({ 'n', 'x' }, 's', '<Nop>') -- disable subsistute key used by surround
      -- require('mini.jump2d').setup()
      require('mini.files').setup({
        windows = {
          preview = true,
          width_preview = 80,
        }
      })
      require('mini.basics').setup({
        options = {
          extra_ui = true,
          win_borders = 'double',
        },
        mappings = {
          windows = true,
        }
      })
      require('mini.clue').setup({
        triggers = {
          -- -- Leader triggers
          { mode = 'n', keys = '<Leader>' },
          { mode = 'x', keys = '<Leader>' },
          -- -- Built-in completion
          { mode = 'i', keys = '<C-x>' },
          --
          -- -- `g` key
          { mode = 'n', keys = 'g' },
          { mode = 'x', keys = 'g' },
          --
          -- -- Marks
          { mode = 'n', keys = "'" },
          { mode = 'n', keys = '`' },
          { mode = 'x', keys = "'" },
          { mode = 'x', keys = '`' },
          --
          -- -- Registers
          { mode = 'n', keys = '"' },
          { mode = 'x', keys = '"' },
          { mode = 'i', keys = '<C-r>' },
          { mode = 'c', keys = '<C-r>' },
          --
          -- -- Window commands
          { mode = 'n', keys = '<C-w>' },
          --
          -- -- `z` key
          { mode = 'n', keys = 'z' },
          { mode = 'x', keys = 'z' },
      },
        clues = {
          { mode = 'n', keys = '<Leader>f', desc = 'Find' },
          -- { mode = 'n', keys = '<Leader>l', desc = 'LSP' },
          -- { mode = 'n', keys = '<Leader>w', desc = 'Window' },
          -- { mode = 'n', keys = '<Leader>s', desc = 'Session' },
          { mode = 'n', keys = '<Leader>b', desc = 'Buffer' },
          -- { mode = 'n', keys = '<Leader>g', desc = 'Git' },
          -- { mode = 'n', keys = '<Leader>u', desc = 'UI' },
          -- { mode = 'n', keys = '<Leader>q', desc = 'NVim' },
          function() MiniClue.gen_clues.g() end,
          function() MiniClue.gen_clues.builtin_completion() end,
          function() MiniClue.gen_clues.marks() end,
          function() MiniClue.gen_clues.registers() end,
          function() MiniClue.gen_clues.windows() end,
          function() MiniClue.gen_clues.z() end,
      },
        window = {
          delay = 300
      }
  })
  end,
  },
  "tami5/sqlite.lua", -- required for firefox
  -- "machakann/vim-sandwich", -- replaces vim-surround below
  "tpope/vim-repeat",
  {
    "windwp/nvim-autopairs",
    config = function()
      require("nvim-autopairs").setup {}
    end
  }, -- auto-close parens etc, replaces delimitmate
  {
    "windwp/nvim-ts-autotag",
    config = function()
      require('nvim-ts-autotag').setup()
    end
  },
  "JoosepAlviste/nvim-ts-context-commentstring",
  {
    "numToStr/Comment.nvim", -- comments
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      "JoosepAlviste/nvim-ts-context-commentstring",
    },
  },
  {
    "folke/todo-comments.nvim",
    dependencies = "nvim-lua/plenary.nvim",
    event = { "BufReadPre", "BufNewFile" },
  },
  {
    "m4xshen/hardtime.nvim",
    dependencies = { "MunifTanjim/nui.nvim", "nvim-lua/plenary.nvim" },
    config = function()
      require("hardtime").setup({
        disabled_filetypes = { "qf", "netrw", "NvimTree", "lazy", "mason", "oil" ,"Bot"},
        hint = true,
      })
      keymap("n", "<F4>", "<CMD>Hardtime toggle<CR>", { desc = "Lazy" })
    end,
  },
--  {
--    "folke/which-key.nvim", -- show mappings
--    config = function()
--      require("which-key").setup()
--  },
  "AckslD/nvim-neoclip.lua",
  "dstein64/vim-startuptime",
  -- { -- filesystem navigation
  --   "kyazdani42/nvim-tree.lua",
  --   dependencies = "kyazdani42/nvim-web-devicons",        -- filesystem icons
  -- },
  {
    'stevearc/oil.nvim',
    opts = {},
    -- Optional dependencies
    dependencies = { { "echasnovski/mini.icons", opts = {} } },
    -- dependencies = { "nvim-tree/nvim-web-devicons" }, -- use if prefer nvim-web-devicons
    config = function()
      require("oil").setup()
      vim.keymap.set("n", "-", "<CMD>Oil<CR>", { desc = "Open parent directory" })
    end,
  },
  "nvim-telescope/telescope-file-browser.nvim",

  -- themes, colors, etc
  "nvim-telescope/telescope-ui-select.nvim",
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "kyazdani42/nvim-web-devicons", opt = true },
  },
  "kyazdani42/nvim-web-devicons",
  -- use "overcache/NeoSolarized"
  "folke/tokyonight.nvim", -- , { "branch": "main" }
  "ishan9299/nvim-solarized-lua",
  --[[
  use {"tjdevries/colorbuddy.nvim",
    config = function()
      require('colorbuddy').setup()
    end
  }
  use {"svrana/neosolarized.nvim",
    config = function()
      require('neosolarized').setup({comment_italics = true,})
    end
  }
  --]]
  "projekt0n/github-nvim-theme",
  "joshdick/onedark.vim",
  {
    "catppuccin/nvim",
    as = "catppuccin",
    config = function()
      require("catppuccin").setup({
        integrations = {
          treesitter = true,
          native_lsp = {
            enabled = true,
            virtual_text = {
              errors = { "italic" },
              hints = { "italic" },
              warnings = { "italic" },
              information = { "italic" },
            },
            underlines = {
              errors = { "underline" },
              hints = { "underline" },
              warnings = { "underline" },
              information = { "underline" },
            },
          },
          lsp_trouble = true,
          gitsigns = true,
          telescope = true,
          which_key = true,
          markdown = true,
        },
        custom_highlights = function(colors)
          return {
            PmenuSel = { bg = colors.surface1, fg = colors.text },
            Pmenu = { bg = colors.mantle, fg = colors.text },
            CmpItemAbbrMatch = { fg = colors.text, bg = colors.surface1 },
            CmpItemAbbrMatchFuzzy = { fg = colors.text, bg = colors.surface1 },
          }
        end,
      })
      vim.g.catppuccin_flavour = "macchiato" -- latte, frappe, macchiato, mocha
    end,
  },
  {
    "Pocco81/true-zen.nvim",
    config = function()
      require("true-zen").setup({
        -- your config goes here
        -- or just leave it empty :)
      })
    end,
  },
})
