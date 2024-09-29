local fn = vim.fn
local letg = vim.g
local key_map = vim.keymap.set

key_map("n", "<F1>", "<CMD>Lazy<CR>", { desc = "Lazy TUI" })

-- require("lazy").setup("plugins")
-- require("lazy").setup({
-- 	spec = {
-- 		-- add LazyVim and import its plugins
-- 		-- { "LazyVim/LazyVim", import = "lazyvim.plugins" },
-- 		-- import/override with your plugins
-- 		{ lazyvim.plugins  = "plugins" },
-- 		-- { import = "plugins" },
-- 	},
-- 	performance = {
-- 		rtp = {
-- 			-- disable some rtp plugins
-- 			disabled_plugins = {
-- 				"gzip",
-- 				-- "matchit",
-- 				-- "matchparen",
-- 				-- "netrwPlugin",
-- 				"tarPlugin",
-- 				"tohtml",
-- 				"tutor",
-- 				"zipPlugin",
-- 			},
-- 		},
-- 	},
-- })
