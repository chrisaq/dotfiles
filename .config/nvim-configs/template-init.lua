-- Add the common modules (one level up + “_common”) to Rtp
local common = vim.fn.stdpath("config"):gsub("/[^/]+$", "/_common")
vim.opt.runtimepath:prepend(common)
-- Load bootstrap
require("bootstrap")            -- ~/.config/nvim-configs/_common/lua/bootstrap.lua

vim.keymap.set("n", "<F1>", "<CMD>Lazy<CR>", { desc = "Lazy TUI" })

-- core config that is loaded before lazy.nvim (~/.config/nvim-configs/CONFIGNAME/lua/user/core.lua
-- require("user/core")

-- Plugins & Lazy configuration
local plugins = {
  { import = "user.plugins" },
}

local lazy_opts = {
  git = {
    url_format = "https://github.com/%s.git", -- comment this line to allow SSH
  },
  concurrency = 5,
}

require("lazy").setup(plugins, lazy_opts)

-- Other config files that are loaded after lazy.nvim
-- require("user/style") -- 10ms
