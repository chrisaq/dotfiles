-- Keymaps for plugins
local key_map = vim.api.nvim_set_keymap
--

-- Mundo
key_map('n', '<F5>', ':MundoToggle<CR>', { noremap = true, silent = true })

-- nvim-tree
key_map('n', '<F6>', ':NvimTreeToggle<CR>', { noremap = true, silent = true })

-- trouble.nvim
key_map("n", "<leader>xx", "<cmd>Trouble<cr>",
  {silent = true, noremap = true}
)
key_map("n", "<leader>xw", "<cmd>Trouble workspace_diagnostics<cr>",
  {silent = true, noremap = true}
)
key_map("n", "<leader>xd", "<cmd>Trouble document_diagnostics<cr>",
  {silent = true, noremap = true}
)
key_map("n", "<leader>xl", "<cmd>Trouble loclist<cr>",
  {silent = true, noremap = true}
)
key_map("n", "<leader>xq", "<cmd>Trouble quickfix<cr>",
  {silent = true, noremap = true}
)
key_map("n", "gR", "<cmd>Trouble lsp_references<cr>",
  {silent = true, noremap = true}
)

