local fn = vim.fn
local letg = vim.g
local keymap = vim.keymap.set
--vim.o.runtimepath = vim.fn.stdpath("data") .. "/site/packer/*/start/*," .. vim.o.runtimepath
--local install_path = fn.stdpath("data") .. "/site/packer/packer/start/packer.nvim"
--if fn.empty(fn.glob(install_path)) > 0 then
--	packer_bootstrap =
--		fn.system({ "git", "clone", "--depth", "1", "https://github.com/wbthomason/packer.nvim", install_path })
--end

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
		"jinh0/eyeliner.nvim",
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
	"tpope/vim-obsession",
  {
    "dhruvasagar/vim-prosession",
    dependencies = "tpope/vim-obsession",
  },
	"907th/vim-auto-save",
	"simnalamburt/vim-mundo",
	"moll/vim-bbye",
	-- Programming
	"nvim-lua/plenary.nvim",
	"nvim-lua/popup.nvim",
	"neovim/nvim-lspconfig",
	"onsails/lspkind.nvim",
	{
		"williamboman/mason.nvim",
		config = function()
      require("mason").setup()
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
		"williamboman/mason-lspconfig.nvim",
		config = function()
			require("mason-lspconfig").setup({
				ensure_installed = {
					"rust_analyzer",
					"bashls",
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
  {
    "glepnir/lspsaga.nvim",
    branch = "main",
    dependencies = "kyazdani42/nvim-web-devicons",
    config = function()
      require('lspsaga').setup({})
    end,
  },
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
  {
    "folke/noice.nvim",
    event = "VeryLazy",
    config = function()
      require("noice").setup({
        lsp = {
          override = {
            ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
            ["vim.lsp.util.stylize_markdown"] = true,
            ["cmp.entry.get_documentation"] = true,
          },
        },
        presets = {
          bottom_search = true, -- use a classic bottom cmdline for search
          command_palette = true, -- position the cmdline and popupmenu together
          long_message_to_split = true, -- long messages will be sent to a split
          inc_rename = false, -- enables an input dialog for inc-rename.nvim
          lsp_doc_border = false, -- add a border to hover docs and signature help  
        },
        routes = {
          {
            filter = {
              event = "mini",
              kind = "",
              find = "null-ls",
            },
            opts = { skip = true },
          }
        },
      })
    end,
    dependencies = {
      "MunifTanjim/nui.nvim",
      "rcarriga/nvim-notify",
    }
  },
  {"lukas-reineke/indent-blankline.nvim", main = "ibl", opts = {}},
	{
		"nvim-treesitter/nvim-treesitter",
		dependencies = {
			"nvim-treesitter/nvim-treesitter-textobjects",
			"nvim-treesitter/nvim-treesitter-refactor",
			"JoosepAlviste/nvim-ts-context-commentstring",
		},
	},
	{
		"nvimtools/none-ls.nvim", -- none-ls Use external formatters and linters
		dependencies = {
			"nvim-lua/plenary.nvim",
		},
	},
	-- Completion
	{
		"hrsh7th/nvim-cmp",
		dependencies = {
			"hrsh7th/cmp-nvim-lsp",
			"hrsh7th/cmp-nvim-lua",
			"hrsh7th/cmp-buffer",
			"hrsh7th/cmp-path",
      "petertriho/cmp-git",
      "hrsh7th/cmp-nvim-lsp-signature-help",
		},
	},
	-- Fuzzy search
	{
		"nvim-telescope/telescope.nvim",
		dependencies = {},
	},
	-- misc
	"tami5/sqlite.lua", -- required for firefox
	"machakann/vim-sandwich", -- replaces vim-surround below
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
	{
		"numToStr/Comment.nvim", -- comments
		config = function()
			require("Comment").setup()
		end,
	},
	"folke/which-key.nvim", -- show mappings
	"AckslD/nvim-neoclip.lua",
	"dstein64/vim-startuptime",
	{ -- filesystem navigation
		"kyazdani42/nvim-tree.lua",
		dependencies = "kyazdani42/nvim-web-devicons",        -- filesystem icons
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
