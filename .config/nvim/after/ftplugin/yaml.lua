-- Use 2 spaces instead of 4 for lua
local o = vim.opt_local

-- Basic Settings
o.cursorcolumn = true -- Highlight the current column
o.shiftwidth = 2 -- Number of spaces to use for each step of (auto)indent
o.softtabstop = 2 -- Number of spaces that a <Tab> counts for while performing editing operations
o.tabstop = 2 -- Number of spaces that a <Tab> in the file counts for
o.expandtab = true -- Expand tab to 2 spaces

-- Folding
vim.opt_local.foldmethod = "indent"
vim.opt_local.foldlevel = 1
-- vim.api.nvim_buf_set_keymap(0, "n", "zj", ':lua NavigateFold("j")<CR>', { noremap = true, silent = true })
-- vim.api.nvim_buf_set_keymap(0, "n", "zk", ':lua NavigateFold("k")<CR>', { noremap = true, silent = true })
