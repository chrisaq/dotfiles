local key_map = vim.api.nvim_set_keymap

require'nvim-treesitter.configs'.setup {
    -- ensure_installed can be "all" or a list of languages { "python", "javascript" }
    ensure_installed = {"python", "bash", "javascript", "clojure", "go"},

    highlight = { -- enable highlighting for all file types
      enable = true, -- you can also use a table with list of langs here (e.g. { "python", "javascript" })
    },
    incremental_selection = {
      enable = true,  -- you can also use a table with list of langs here (e.g. { "python", "javascript" })
      disable = { "cpp", "lua" },
      keymaps = {                       -- mappings for incremental selection (visual mappings)
        init_selection = "gnn",         -- maps in normal mode to init the node/scope selection
        node_incremental = "grn",       -- increment to the upper named parent
        scope_incremental = "grc",      -- increment to the upper scope (as defined in locals.scm)
        node_decremental = "grm",       -- decrement to the previous node
      }
    },
    textobjects = {
      -- These are provided by
      select = {
        enable = true,  -- you can also use a table with list of langs here (e.g. { "python", "javascript" })
        keymaps = {
          -- You can use the capture groups defined here:
	      -- https://github.com/nvim-treesitter/nvim-treesitter-textobjects/blob/master/queries/c/textobjects.scm
          ["af"] = "@function.outer",
          ["if"] = "@function.inner",
          ["ab"] = "@block.outer",
          ["ib"] = "@block.inner",
          ["as"] = "@statement.outer",
          ["is"] = "@statement.inner",
        },
      },
    },
    context_commentstring = {
      enable = true
    },
}


key_map("n", "gd", [[<Cmd>lua vim.lsp.buf.definition()<CR>]],
  { noremap = true, silent = true })
key_map("n", "<C-]>", [[<Cmd>lua vim.lsp.buf.definition()<CR>]],
  { noremap = true, silent = true })
key_map("n", "gD", [[<Cmd>lua vim.lsp.buf.declaration()<CR>]],
  { noremap = true, silent = true })
key_map("n", "gr", [[<Cmd>lua vim.lsp.buf.references()<CR>]],
  { noremap = true, silent = true })
key_map("n", "gi", [[<Cmd>lua vim.lsp.buf.implementation()<CR>]],
  { noremap = true, silent = true })
key_map("n", "gf", [[<Cmd>lua vim.lsp.buf.formatting()<CR>]],
  { noremap = true, silent = true })
key_map("n", "gn", [[<Cmd>lua vim.lsp.buf.rename()<CR>]],
  { noremap = true, silent = true })
key_map("n", "<C-k>", [[<Cmd>lua vim.lsp.buf.signature_help()<CR>]],
  { noremap = true, silent = true })

--[[
require'nvim-treesitter.configs'.setup {
  refactor = {
    highlight_definitions = {
      enable = true,
      -- Set to false if you have an `updatetime` of ~100.
      clear_on_cursor_move = true,
    },
    highlight_current_scope = { enable = true }, -- highlight scope, such as function or class
    smart_rename = {
      enable = true,
      keymaps = {
      smart_rename = "grr",
      },
    },
  },
}
--]]
