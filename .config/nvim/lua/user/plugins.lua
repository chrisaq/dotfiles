local fn = vim.fn
local letg = vim.g
-- vim.o.runtimepath = vim.fn.stdpath('data') .. '/site/pack/*/start/*,' .. vim.o.runtimepath
vim.o.runtimepath = vim.fn.stdpath('data') .. '/site/packer/*/start/*,' .. vim.o.runtimepath
local install_path = fn.stdpath('data')..'/site/packer/packer/start/packer.nvim'
if fn.empty(fn.glob(install_path)) > 0 then
  packer_bootstrap = fn.system({'git', 'clone', '--depth', '1', 'https://github.com/wbthomason/packer.nvim', install_path})
end

return require('packer').startup(function(use)
  use "wbthomason/packer.nvim"
  use 'lewis6991/impatient.nvim'
  -- Git
  use "tpope/vim-git"
  use "tpope/vim-fugitive"
  use ({"lewis6991/gitsigns.nvim",
    config = function()
      require('gitsigns').setup()
    end
  })
-- Movement
  use {"unblevable/quick-scope",  -- color next match for f,F,t,T
    setup = [[vim.g.qs_highlight_on_keys = {'f', 'F', 't', 'T'}]]
  }
  use "ap/vim-you-keep-using-that-word"  	-- disables cw/cW exception of not including the space(s) after word
-- Sessions
  use "tpope/vim-obsession"
  use {"dhruvasagar/vim-prosession",
  }
  use {"907th/vim-auto-save",
  }
  use "simnalamburt/vim-mundo"
  use "moll/vim-bbye"
-- Programming
  use "nvim-lua/plenary.nvim"
  use "nvim-lua/popup.nvim"
  use "neovim/nvim-lspconfig"
  use "onsails/lspkind.nvim"
  use "williamboman/nvim-lsp-installer" -- , { "branch": "main" }
  use "folke/trouble.nvim" -- show list of issues
  use "lukas-reineke/indent-blankline.nvim"
  use({
    "nvim-treesitter/nvim-treesitter",
    requires = {
      "nvim-treesitter/nvim-treesitter-textobjects",
      "nvim-treesitter/nvim-treesitter-refactor",
      "JoosepAlviste/nvim-ts-context-commentstring"
    }
  })
  use({
    "jose-elias-alvarez/null-ls.nvim", -- Null-LS Use external formatters and linters
    requires = {
        "nvim-lua/plenary.nvim",
    }
  })
-- Completion
  use({
    "hrsh7th/nvim-cmp",
    requires = {
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "saadparwaiz1/cmp_luasnip",
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-nvim-lua",
      "L3MON4D3/LuaSnip",
      "rafamadriz/friendly-snippets",
    }
  })
-- Fuzzy search
  use({
    "nvim-telescope/telescope.nvim",
    requires = {
    }
  })
-- misc
  use "tami5/sqlite.lua" -- required for firefox
  use "machakann/vim-sandwich"  -- replaces vim-surround below
  use "tpope/vim-repeat"
  use "tmsvg/pear-tree" -- auto-close parens etc, replaces delimitmate
  use {"numToStr/Comment.nvim", -- comments
    config = function()
        require('Comment').setup()
    end}
  use "junegunn/vim-easy-align"
  use "folke/which-key.nvim" -- show mappings
  use "AckslD/nvim-neoclip.lua"
  use "dstein64/vim-startuptime"
  use {                                              -- filesystem navigation
    "kyazdani42/nvim-tree.lua",
    requires = "kyazdani42/nvim-web-devicons"        -- filesystem icons
  }
  use "nvim-telescope/telescope-file-browser.nvim"

-- themes, colors, etc
  use "nvim-telescope/telescope-ui-select.nvim"
  use {
    'nvim-lualine/lualine.nvim',
    requires = { 'kyazdani42/nvim-web-devicons', opt = true }
}
  use "kyazdani42/nvim-web-devicons"
  -- use "overcache/NeoSolarized"
  use "folke/tokyonight.nvim" -- , { "branch": "main" }
  use "ishan9299/nvim-solarized-lua"
  use("projekt0n/github-nvim-theme")
  use("joshdick/onedark.vim")

  -- Automatically set up your configuration after cloning packer.nvim
  -- Put this at the end after all plugins
  if packer_bootstrap then
    require('packer').sync()
  end
end)

