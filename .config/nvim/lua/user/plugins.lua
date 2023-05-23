local fn = vim.fn
local letg = vim.g
local keymap = vim.keymap.set
-- vim.o.runtimepath = vim.fn.stdpath('data') .. '/site/pack/*/start/*,' .. vim.o.runtimepath
vim.o.runtimepath = vim.fn.stdpath("data") .. "/site/packer/*/start/*," .. vim.o.runtimepath
local install_path = fn.stdpath("data") .. "/site/packer/packer/start/packer.nvim"
if fn.empty(fn.glob(install_path)) > 0 then
	packer_bootstrap =
		fn.system({ "git", "clone", "--depth", "1", "https://github.com/wbthomason/packer.nvim", install_path })
end

return require("packer").startup(function(use)
	use("wbthomason/packer.nvim")
	use("lewis6991/impatient.nvim")
	-- Git
	use("tpope/vim-git")
	use("tpope/vim-fugitive")
	use({
		"lewis6991/gitsigns.nvim",
		config = function()
			require("gitsigns").setup()
		end,
	})
	-- Movement
	--  use ({"unblevable/quick-scope",  -- color next match for f,F,t,T
	--    setup = [[vim.g.qs_highlight_on_keys = {'f', 'F', 't', 'T'}]]
	--  })
	-- quick-scope in lua
	use({
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
	})
	use("ap/vim-you-keep-using-that-word") -- disables cw/cW exception of not including the space(s) after word
	-- Sessions
	use("tpope/vim-obsession")
	use({ "dhruvasagar/vim-prosession" })
	use({ "907th/vim-auto-save" })
	use("simnalamburt/vim-mundo")
	use("moll/vim-bbye")
	-- Programming
	use("nvim-lua/plenary.nvim")
	use("nvim-lua/popup.nvim")
	use("neovim/nvim-lspconfig")
	use("onsails/lspkind.nvim")
	use({
		"williamboman/mason.nvim",
		config = function()
			require("mason.settings").set({
				ui = {
                  border = "rounded",
                  package_installed = "✓",
                },
				-- log_level = vim.log.levels.DEBUG
			})
		end,
	})
	use({
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
	})
  use({
    "glepnir/lspsaga.nvim",
    branch = "main",
    requires = "kyazdani42/nvim-web-devicons",
    config = function()
      require('lspsaga').setup({})
    end,
  })
	use({
		"VonHeikemen/lsp-zero.nvim",
		requires = {
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
	})
	use({"folke/trouble.nvim",
    requires = "kyazdani42/nvim-web-devicons",
    config = function()
      require("trouble").setup {
        mode = "document_diagnostics",
      }
    end
  }) -- show list of issues
  use({
    "folke/noice.nvim",
    config = function()
      require("noice").setup()
    end,
    requires = {
      "MunifTanjim/nui.nvim",
      "rcarriga/nvim-notify",
    }
  })
	use("lukas-reineke/indent-blankline.nvim")
	use({
		"nvim-treesitter/nvim-treesitter",
		requires = {
			"nvim-treesitter/nvim-treesitter-textobjects",
			"nvim-treesitter/nvim-treesitter-refactor",
			"JoosepAlviste/nvim-ts-context-commentstring",
		},
	})
	use({
		"jose-elias-alvarez/null-ls.nvim", -- Null-LS Use external formatters and linters
		requires = {
			"nvim-lua/plenary.nvim",
		},
	})
	-- Completion
	use({
		"hrsh7th/nvim-cmp",
		requires = {
			"hrsh7th/cmp-nvim-lsp",
			"hrsh7th/cmp-nvim-lua",
			"hrsh7th/cmp-buffer",
			"hrsh7th/cmp-path",
      "petertriho/cmp-git",
      "hrsh7th/cmp-nvim-lsp-signature-help",
		},
	})
	-- Fuzzy search
	use({
		"nvim-telescope/telescope.nvim",
		requires = {},
	})
	-- misc
	use("tami5/sqlite.lua") -- required for firefox
	use("machakann/vim-sandwich") -- replaces vim-surround below
	use("tpope/vim-repeat")
	use({
    "windwp/nvim-autopairs",
    config = function()
      require("nvim-autopairs").setup {}
    end
  }) -- auto-close parens etc, replaces delimitmate
  use({
    "windwp/nvim-ts-autotag",
    config = function()
      require('nvim-ts-autotag').setup()
    end
  })
	use({
		"numToStr/Comment.nvim", -- comments
		config = function()
			require("Comment").setup()
		end,
	})
	use("folke/which-key.nvim") -- show mappings
	use("AckslD/nvim-neoclip.lua")
	use("dstein64/vim-startuptime")
	use({ -- filesystem navigation
		"kyazdani42/nvim-tree.lua",
		requires = "kyazdani42/nvim-web-devicons",        -- filesystem icons
	})
	use("nvim-telescope/telescope-file-browser.nvim")

	-- themes, colors, etc
	use("nvim-telescope/telescope-ui-select.nvim")
	use({
		"nvim-lualine/lualine.nvim",
		requires = { "kyazdani42/nvim-web-devicons", opt = true },
	})
	use("kyazdani42/nvim-web-devicons")
	-- use "overcache/NeoSolarized"
	use("folke/tokyonight.nvim") -- , { "branch": "main" }
	use("ishan9299/nvim-solarized-lua")
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
	use("projekt0n/github-nvim-theme")
	use("joshdick/onedark.vim")
	use({
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
	})
	use({
		"Pocco81/true-zen.nvim",
		config = function()
			require("true-zen").setup({
				-- your config goes here
				-- or just leave it empty :)
			})
		end,
	})

	-- Automatically set up your configuration after cloning packer.nvim
	-- Put this at the end after all plugins
	if packer_bootstrap then
		require("packer").sync()
	end
end)
