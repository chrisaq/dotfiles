-- ─────────────────────────────────────────────────────────────────────────────
-- Bootstrap lazy.nvim ---------------------------------------------------------
-- ─────────────────────────────────────────────────────────────────────────────
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "--single-branch",
    "https://github.com/folke/lazy.nvim.git",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- ─────────────────────────────────────────────────────────────────────────────
-- Plugins & Lazy configuration ------------------------------------------------
-- ─────────────────────────────────────────────────────────────────────────────
vim.keymap.set("n", "<F1>", "<CMD>Lazy<CR>", { desc = "Lazy TUI" })

require("user/core")
require("user/core_maps")

local plugins = {
  { import = "user.plugins" },
  { import = "user.plugins.lsp" },
}

local lazy_opts = {
  -- ░ HTTPS‑only cloning ░
  git = {
    url_format = "https://github.com/%s.git", -- comment this line to allow SSH
  },
  concurrency = 5, -- reduce simultaneous clones (GitHub drops >10 SSH conns)
}

require("lazy").setup(plugins, lazy_opts)

require("user/treesitter") -- ~0ms
require("user/telescope") -- 30ms
require("user/style") -- 10ms
