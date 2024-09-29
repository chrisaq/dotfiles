local key_map = vim.api.nvim_set_keymap

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

key_map("n", "<F1>", "<CMD>Lazy<CR>", { desc = "Lazy TUI" })

require("user/core")
require("user/core_maps")

-- require("lazy")
-- require("lazy").setup("plugins")
-- require("lazy").setup({ { import = "user.plugins" }, })
require("lazy").setup(
  {
    { import = "user.plugins" },
    { import = "user.plugins.lsp" },
    performance = {
      rtp = {
        -- disable some rtp plugins
        disabled_plugins = {
          "gzip",
          -- "matchit",
          -- "matchparen",
          -- "netrwPlugin",
          "tarPlugin",
          "tohtml",
          "tutor",
          "zipPlugin",
        },
      },
    },
  }
)

-- require("user/lsp") -- 11ms
require("user/treesitter") -- ~0ms
-- require("user/completion") -- 850ms, totally broken
require("user/telescope") -- 30ms
require("user/style") -- 10ms
