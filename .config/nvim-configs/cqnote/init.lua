-- New nvim instance config

-- only change the line below for new config
local nv_name = 'cqnote'

local nv_conf = '~/.config/nvim-configs/'
local nv_data = '~/.local/share/nvim-configs/'

vim.opt.runtimepath:remove(vim.fn.expand('~/.config/nvim'))
vim.opt.packpath:remove(vim.fn.expand('~/.local/share/nvim/site'))

vim.opt.runtimepath:append(vim.fn.expand(nv_conf..nv_name))
vim.opt.packpath:append(vim.fn.expand(nv_data..nv_name..'/site'))

local old_stdpath = vim.fn.stdpath
vim.fn.stdpath = function(value)
    if value == "data" then
        -- return "your/modified/path"
        return vim.fn.expand(nv_data..nv_name)
    end
    return old_stdpath(value)
end
-- END: New nvim instance config

-- Auto install packer on new machines
local ensure_packer = function()
  local fn = vim.fn
  -- local install_path = fn.stdpath('data')..'/site/pack/packer/start/packer.nvim'
  local install_path = fn.expand(nv_data..nv_name..'/site/pack/packer/start/packer.nvim')
  if fn.empty(fn.glob(install_path)) > 0 then
    fn.system({'git', 'clone', '--depth', '1', 'https://github.com/wbthomason/packer.nvim', install_path})
    vim.cmd [[packadd packer.nvim]]
    return true
  end
  return false
end

local packer_bootstrap = ensure_packer()

return require('packer').startup(function(use)
  use 'wbthomason/packer.nvim'
  -- My plugins here
  -- use 'foo1/bar1.nvim'
  -- use 'foo2/bar2.nvim'

  -- Automatically set up your configuration after cloning packer.nvim
  -- Put this at the end after all plugins
  if packer_bootstrap then
    require('packer').sync()
  end
end)

-- require("core")
-- require("plugins")
