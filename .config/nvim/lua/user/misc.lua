require("which-key").setup {
  -- your configuration comes here
  -- or leave it empty to use the default settings
  -- refer to the configuration section below
}

-- keymaps
--
local key_map = vim.api.nvim_set_keymap

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

