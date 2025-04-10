local letg = vim.g
local key_map = vim.keymap.set
return {
  "lewis6991/impatient.nvim",
  {
  "folke/snacks.nvim",
  priority = 1000,
  lazy = false,
  ---@type snacks.Config
    opts = {
      -- your configuration comes here
      -- or leave it empty to use the default settings
      -- refer to the configuration section below
      bigfile = { enabled = true },
      dashboard = { enabled = true },
      explorer = { enabled = true },
      indent = { enabled = false },
      input = { enabled = true },
      picker = { enabled = true },
      notifier = { enabled = true },
      quickfile = { enabled = true },
      scope = { enabled = true },
      scroll = { enabled = true },
      statuscolumn = { enabled = true },
      words = { enabled = true },
    },
  },
  -- Git
  "tpope/vim-git",
  "tpope/vim-fugitive",
  {
    "christoomey/vim-tmux-navigator",
    -- CQmapping: insert: C-h -- move left, vim split or tmux pane (vim-tmux-navigator)
    -- CQmapping: insert: C-j -- move down, vim split or tmux pane (vim-tmux-navigator)
    -- CQmapping: insert: C-k -- move up, vim split or tmux pane (vim-tmux-navigator)
    -- CQmapping: insert: C-l -- move right, vim split or tmux pane (vim-tmux-navigator)
    cmd = {
      "TmuxNavigateLeft",
      "TmuxNavigateDown",
      "TmuxNavigateUp",
      "TmuxNavigateRight",
      "TmuxNavigatePrevious",
    },
    keys = {
      { "<c-h>", "<cmd><C-U>TmuxNavigateLeft<cr>" },
      { "<c-j>", "<cmd><C-U>TmuxNavigateDown<cr>" },
      { "<c-k>", "<cmd><C-U>TmuxNavigateUp<cr>" },
      { "<c-l>", "<cmd><C-U>TmuxNavigateRight<cr>" },
      { "<c-\\>", "<cmd><C-U>TmuxNavigatePrevious<cr>" },
    },
  },
  {
    "lewis6991/gitsigns.nvim",
    config = function()
      require("gitsigns").setup()
      key_map("n", "<leader>gs", "<cmd>Gitsigns preview_hunk<CR>", { desc = "Git preview hunk" })
      key_map("n", "<leader>gb", "<cmd>Gitsigns toggle_current_line_blame<CR>", { desc = "Git toggle blame" })
    end,
  },
  -- Movement
  --  use ({"unblevable/quick-scope",  -- color next match for f,F,t,T
  --    setup = [[vim.g.qs_highlight_on_keys = {'f', 'F', 't', 'T'}]]
  --  })
  -- quick-scope in lua
  {
    "jinh0/eyeliner.nvim", -- f/F gives indicator on line where to jump
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
  "ap/vim-you-keep-using-that-word", -- disables cw/cW exception of not including the space(s, after word
  -- Sessions
  "tpope/vim-obsession", -- continuously update session file
  {
    "dhruvasagar/vim-prosession", -- handle and switch between sessions
    dependencies = "tpope/vim-obsession",
    init = function()
      letg.prosession_dir = "~/.config/nvim/session/"
      letg.prosession_on_startup = 1
    end,
  },
  {
    "907th/vim-auto-save",
    init = function()
      letg.auto_save = 0
      letg.auto_save_silents = 1
    end,
  },
  {
    "simnalamburt/vim-mundo", -- undo enhanced, f6
    config = function()
      key_map("n", "<F5>", ":MundoToggle<CR>", { noremap = true, silent = true })
    end,
  },
  "moll/vim-bbye", -- closing buffers will not remove windows
  -- Programming
  "nvim-lua/plenary.nvim", -- library of common lua functions
  "nvim-lua/popup.nvim", -- utility package for popups
  {
    "MeanderingProgrammer/render-markdown.nvim",
    opts = { file_types = { "markdown", "Avante" } },
    -- dependencies = { 'nvim-treesitter/nvim-treesitter', 'echasnovski/mini.nvim' }, -- if you use the mini.nvim suite
    dependencies = { "nvim-treesitter/nvim-treesitter", "echasnovski/mini.icons" }, -- if you use standalone mini plugins
  },
  {
    "folke/trouble.nvim",
    opts = {},
    dependencies = "echasnovski/mini.icons",
    cmd = "Trouble",
    keys = {
      {
        "<leader>xx",
        "<cmd>Trouble diagnostics toggle<cr>",
        desc = "Diagnostics (Trouble)",
      },
      {
        "<leader>xX",
        "<cmd>Trouble diagnostics toggle filter.buf=0<cr>",
        desc = "Buffer Diagnostics (Trouble)",
      },
      {
        "<leader>cs",
        "<cmd>Trouble symbols toggle focus=false<cr>",
        desc = "Symbols (Trouble)",
      },
      {
        "<leader>cl",
        "<cmd>Trouble lsp toggle focus=false win.position=right<cr>",
        desc = "LSP Definitions / references / ... (Trouble)",
      },
      {
        "<leader>xL",
        "<cmd>Trouble loclist toggle<cr>",
        desc = "Location List (Trouble)",
      },
      {
        "<leader>xQ",
        "<cmd>Trouble qflist toggle<cr>",
        desc = "Quickfix List (Trouble)",
      },
    },
  },
  {
    "lukas-reineke/indent-blankline.nvim",
    main = "ibl",
    -- opts = {},
    config = function()
      local highlight = {
        "CursorColumn",
        "Whitespace",
      }
      require("ibl").setup({
        indent = { highlight = highlight, char = "" },
        whitespace = {
          highlight = highlight,
          remove_blankline_trail = false,
        },
        scope = { enabled = true },
      })
    end,
  },
  {
    "nvim-treesitter/nvim-treesitter",
    dependencies = {
      "nvim-treesitter/nvim-treesitter-textobjects",
      "nvim-treesitter/nvim-treesitter-refactor",
      "JoosepAlviste/nvim-ts-context-commentstring",
    },
  },
  {
    "Exafunction/codeium.nvim",
    -- locking to this commit until https://github.com/Exafunction/codeium-vim/issues/236 or 232 is resolved
    commit = "937667b2cadc7905e6b9ba18ecf84694cf227567",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "hrsh7th/nvim-cmp",
    },
    config = function()
      require("codeium").setup({
        enable_chat = true,
      })
    end,
  },
  {
    "supermaven-inc/supermaven-nvim",
    config = function()
      require("supermaven-nvim").setup({
        keymaps = {
          -- accept_suggestion = "<CR>",
          --   clear_suggestion = "<C-]>",
          --   accept_word = "<C-j>",
        },
        disable_inline_completion = true,
        disable_keymaps = true,
      })
    end,
  },
  {
    "yetone/avante.nvim",
    event = "VeryLazy",
    lazy = false,
    version = false, -- set this if you want to always pull the latest change
    opts = {
      -- add any opts here
      provider = "claude",
      claude = {
        api_key_name = "cmd:cat /home/chrisq/.config/tokens/claude.token",
      }
    },
    -- if you want to build from source then do `make BUILD_FROM_SOURCE=true`
    build = "make",
    -- build = "powershell -ExecutionPolicy Bypass -File Build.ps1 -BuildFromSource false" -- for windows
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "stevearc/dressing.nvim",
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
      --- The below dependencies are optional,
      "echasnovski/mini.icons",
      -- "zbirenbaum/copilot.lua", -- for providers='copilot'
      {
        -- support for image pasting
        "HakonHarnes/img-clip.nvim",
        event = "VeryLazy",
        opts = {
          -- recommended settings
          default = {
            embed_image_as_base64 = false,
            prompt_for_file_name = false,
            drag_and_drop = {
              insert_mode = true,
            },
            -- required for Windows users
            use_absolute_path = false,
          },
        },
      },
    },
  },
  {
    "robitx/gp.nvim",
    config = function()
      local conf = {
        -- For customization, refer to Install > Configuration in the Documentation/Readme
        providers = {
          openai = {
            endpoint = "https://api.openai.com/v1/chat/completions",
            secret = { "bash", "-c", "cat ~/.config/tokens/openai.token" },
          },
          anthropic = {
            endpoint = "https://api.anthropic.com/v1/messages",
            secret = { "bash", "-c", "cat ~/.config/tokens/claude.token" },
          },
        },
      }
      require("gp").setup(conf)
      -- Setup shortcuts here (see Usage > Shortcuts in the Documentation/Readme)
    end,
  },
  -- Formatting
  -- Fuzzy search
  {
    "nvim-telescope/telescope.nvim",
    dependencies = {},
  },
  -- misc
  "lewis6991/satellite.nvim",
  {
    -- precognition.nvim - shown movement hints
    "tris203/precognition.nvim",
    event = "VeryLazy",
    config = function()
      require("precognition").setup({
        startVisible = false,
      })
      key_map("n", "<F3>", "<CMD>Precognition toggle<CR>", { desc = "Precognition toggle" })
    end,
  },
  {
    "echasnovski/mini.icons",
    opts = {},
    lazy = true,
    specs = {
      { "nvim-tree/nvim-web-devicons", enabled = false, optional = true },
    },
    init = function()
      package.preload["nvim-web-devicons"] = function()
        require("mini.icons").mock_nvim_web_devicons()
        return package.loaded["nvim-web-devicons"]
      end
    end,
    config = function()
      require("mini.icons").setup({
        lsp = {
          ellipsis_char = { glyph = '…', hl = 'MiniIconsRed' },
          copilot = { glyph = '', hl = 'MiniIconsOrange' },
          supermaven = { glyph = '', hl = 'MiniIconsYellow' },
          codeium = { glyph = '', hl = 'MiniIconsGreen' },
          otter = { glyph = '🦦', hl = 'MiniIconsCyan' },
          cody = { glyph = '', hl = 'MiniIconsAzure' },
          cmp_r = { glyph = 'R', hl = 'MiniIconsBlue' },
        },
      })
    end
  },
  {
    "echasnovski/mini.nvim",
    config = function()
      require("mini.ai").setup()
      require("mini.align").setup()
      require("mini.cursorword").setup()
      require("mini.extra").setup()
      require("mini.trailspace").setup({ only_in_normal_buffers = true })
      key_map("n", "<leader><Space>", ":lua MiniTrailspace.trim()<CR>", { desc = "Trailspace clear all" })
      require("mini.surround").setup()
      key_map({ "n", "x" }, "s", "<Nop>") -- disable substitute key used by surround
      require("mini.basics").setup({
        options = {
          extra_ui = true,
          win_borders = "double",
        },
        mappings = {
          windows = true,
        },
      })
      require("mini.clue").setup({
        triggers = {
          -- -- Leader triggers
          { mode = "n", keys = "<Leader>" },
          { mode = "x", keys = "<Leader>" },
          -- -- Built-in completion
          { mode = "i", keys = "<C-x>" },
          --
          -- -- `g` key
          { mode = "n", keys = "g" },
          { mode = "x", keys = "g" },
          --
          -- -- Marks
          { mode = "n", keys = "'" },
          { mode = "n", keys = "`" },
          { mode = "x", keys = "'" },
          { mode = "x", keys = "`" },
          --
          -- -- Registers
          { mode = "n", keys = '"' },
          { mode = "x", keys = '"' },
          { mode = "i", keys = "<C-r>" },
          { mode = "c", keys = "<C-r>" },
          --
          -- -- Window commands
          { mode = "n", keys = "<C-w>" },
          --
          -- -- `z` key
          { mode = "n", keys = "z" },
          { mode = "x", keys = "z" },
        },
        clues = {
          { mode = "n", keys = "<Leader>f", desc = "Find" },
          -- { mode = 'n', keys = '<Leader>l', desc = 'LSP' },
          -- { mode = 'n', keys = '<Leader>w', desc = 'Window' },
          -- { mode = 'n', keys = '<Leader>s', desc = 'Session' },
          { mode = "n", keys = "<Leader>b", desc = "Buffer" },
          -- { mode = 'n', keys = '<Leader>g', desc = 'Git' },
          -- { mode = 'n', keys = '<Leader>u', desc = 'UI' },
          -- { mode = 'n', keys = '<Leader>q', desc = 'NVim' },
          function()
            MiniClue.gen_clues.g()
          end,
          function()
            MiniClue.gen_clues.builtin_completion()
          end,
          function()
            MiniClue.gen_clues.marks()
          end,
          function()
            MiniClue.gen_clues.registers()
          end,
          function()
            MiniClue.gen_clues.windows()
          end,
          function()
            MiniClue.gen_clues.z()
          end,
        },
        window = {
          delay = 300,
        },
      })
    end,
  },
  "tami5/sqlite.lua", -- required for firefox
  -- "machakann/vim-sandwich", -- replaces vim-surround below
  "tpope/vim-repeat",
  {
    "windwp/nvim-autopairs",
    config = function()
      require("nvim-autopairs").setup({
        enable_check_bracket_line = false,
        check_ts = true,
        ignored_next_char = "[%w%.]",
        fast_wrap = {
          map = "<M-e>",
          chars = { "{", "[", "(", "\"", "'" },
          pattern = [=[[%"%"%)%>%]%)%}%,]]=],
          end_key = "$",
          keys = "qwertyuiopzxcvbnmasdfghjkl",
          check_comma = true,
          highlight = "Search",
          highlight_grey = "Comment"
        },
      })
    end,
  }, -- auto-close parens etc, replaces delimitmate
  {
    "windwp/nvim-ts-autotag",
    config = function()
      require("nvim-ts-autotag").setup()
    end,
  },
  "JoosepAlviste/nvim-ts-context-commentstring",
  {
    "numToStr/Comment.nvim", -- comments
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      "JoosepAlviste/nvim-ts-context-commentstring",
    },
    opts = {
      padding = true,
      sticky = true,
      ignore = nil,
      toggler = {
        line = "gcc",
        block = "gbc",
      },
      opleader = {
        line = "gc",
        block = "gb",
      },
      extra = {
        above = "gcO",
        below = "gco",
        eol = "gcA",
      },
      mappings = {
        basic = true,
        extra = true,
        extended = false,
      },
      pre_hook = nil,
      post_hook = nil,
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
        disabled_filetypes = { "qf", "netrw", "NvimTree", "lazy", "mason", "oil", "Bot", "vim", "help", "Avante", "trouble", "MundoDiff" },
        hint = true,
      })
      key_map("n", "<f4>", "<cmd>hardtime toggle<cr>", { desc = "hardtime toggle" })
    end,
  },
  "acksld/nvim-neoclip.lua",
  "dstein64/vim-startuptime",
  {
    "stevearc/oil.nvim",
    opts = {},
    -- optional dependencies
    dependencies = { { "echasnovski/mini.icons", opts = {} } },
    config = function()
      require("oil").setup()
      key_map("n", "-", "<cmd>Oil<cr>", { desc = "open parent directory" })
    end,
  },
  "nvim-telescope/telescope-file-browser.nvim",

  -- themes, colors, etc
  "nvim-telescope/telescope-ui-select.nvim",
  {
    "nvim-lualine/lualine.nvim",
    opts = {
      options = {
        icons_enabled = true,
        theme = "auto",
        component_separators = { left = "", right = "" },
        section_separators = { left = "", right = "" },
        disabled_filetypes = {},
        always_divide_middle = true,
        globalstatus = false,
      },
      sections = {
        lualine_a = { "mode" },
        lualine_b = { "branch", "diff", "diagnostics" },
        lualine_c = { "filename" },
        lualine_x = { "encoding", "fileformat", "filetype" },
        lualine_y = { "progress" },
        lualine_z = { "location" },
      },
      inactive_sections = {
        lualine_a = {},
        lualine_b = {},
        lualine_c = { "filename" },
        lualine_x = { "location" },
        lualine_y = {},
        lualine_z = {},
      },
      tabline = {},
      extensions = {},
      inactive_winbar = {},
    },
  },
  "folke/tokyonight.nvim", -- , { "branch": "main" }
  "ishan9299/nvim-solarized-lua",
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
    "sphamba/smear-cursor.nvim",
    opts = {},
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
}
