-- Keymaps for plugins
local key_map = vim.api.nvim_set_keymap
--

-- Mundo
key_map('n', '<F5>', ':MundoToggle<CR>', { noremap = true, silent = true })

-- nvim-tree
key_map('n', 'fn', ':NvimTreeToggle<CR>', { noremap = true, silent = true })

