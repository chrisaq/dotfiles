# Neovim Configs

This is a collection of my personal neovim configs.


## How it's done

The goal is be able to create new nvim configs with as little work as possible while keeping it simple.

### nv script

There's a small script named `nv` which is a wrapper around `nvim`.

This script will use the name it is executed as to set the `NVIM_APPNAME` environment variable,
which in turn is used to point to the correct config directory.

So, for example, if you symlink `ubervim` to `nv`, then `ubervim` will use the config from `~/.config/nvim-configs/ubervim`.

### Common bootstrap file

While we want to keep the configs as simple as possible, we also want to reuse the very basic bootstrapping code.
This is mainly the `lazy.nvim` plugin manager and location of additional plugins.

This boostrap file is located at `~/.config/nvim-configs/_common/bootstrap.lua`.

To use this bootstrap file, simply add the following to your `init.lua` file, or just copy it from `nvim-configs/template-init.lua`

```lua
-- Add the common modules (one level up + “_common”) to Rtp
local common = vim.fn.stdpath("config"):gsub("/[^/]+$", "/_common")
vim.opt.runtimepath:prepend(common)
-- Load bootstrap
require("bootstrap")            -- ~/.config/nvim-configs/_common/lua/bootstrap.lua

vim.keymap.set("n", "<F1>", "<CMD>Lazy<CR>", { desc = "Lazy TUI" })

-- require("user/core") -- core config that is loaded before lazy.nvim (~/.config/nvim-configs/CONFIGNAME/lua/user/core.lua

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
-- require("user/style") -- Other config files that are loaded after lazy.nvim
```
