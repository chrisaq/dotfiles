-- Telescope
local actions = require "telescope.actions"
local action_state = require "telescope.actions.state"

-- https://github.com/nvim-telescope/telescope.nvim/issues/1048
local telescope_custom_actions = {}

function telescope_custom_actions._multiopen(prompt_bufnr, open_cmd)
  local picker = action_state.get_current_picker(prompt_bufnr)
  local num_selections = #picker:get_multi_selection()
  if not num_selections or num_selections <= 1 then
    actions.add_selection(prompt_bufnr)
  end
  actions.send_selected_to_qflist(prompt_bufnr)
  vim.cmd("cfdo " .. open_cmd)
end

function telescope_custom_actions.multi_selection_open(prompt_bufnr)
  telescope_custom_actions._multiopen(prompt_bufnr, "edit")
end

require("telescope").setup {
  extensions = {
    fzf = {
      fuzzy = true, -- false will only do exact matching
      override_generic_sorter = true,
      override_file_sorter = true,
      case_mode = "smart_case", -- this is default
    },
    file_browser = {
      hidden = true,
    },
    ["ui-select"] = {
      require("telescope.themes").get_cursor(),
    },
    bookmarks = {
      selected_browser = "brave",
      url_open_command = "open",
    },
    command_palette = {
    },
  },
  defaults = {
    preview = {
      timeout = 500,
      msg_bg_fillchar = "",
    },
    multi_icon = " ",
    vimgrep_arguments = {
      "rg",
      "--color=never",
      "--no-heading",
      "--with-filename",
      "--line-number",
      "--column",
      "--smart-case",
      "--hidden",
    },
    prompt_prefix = "❯ ",
    selection_caret = "❯ ",
    sorting_strategy = "ascending",
    color_devicons = true,
    layout_config = {
      prompt_position = "bottom",
      horizontal = {
        width_padding = 0.04,
        height_padding = 0.1,
        preview_width = 0.6,
      },
      vertical = {
        width_padding = 0.05,
        height_padding = 1,
        preview_height = 0.5,
      },
    },

    -- using custom temp multi-select maps
    -- https://github.com/nvim-telescope/telescope.nvim/issues/1048
    mappings = {
      n = {
        ["<Del>"] = actions.close,
        ["<C-A>"] = telescope_custom_actions.multi_selection_open,
        ['<c-d>'] = require('telescope.actions').delete_buffer,
      },
      i = {
        ["<esc>"] = actions.close,
        ["<C-A>"] = telescope_custom_actions.multi_selection_open,
      },
    },
    dynamic_preview_title = true,
    winblend = 4,
  },
}

-- Extensions --
--
require('neoclip').setup({
    history = 1000,
    enable_persistent_history = false,
    length_limit = 1048576,
    continuous_sync = false,
    db_path = vim.fn.stdpath("data") .. "/databases/neoclip.sqlite3",
    filter = nil,
    preview = true,
    default_register = '"',
    default_register_macros = 'q',
    enable_macro_history = true,
    content_spec_column = false,
    on_paste = {
    set_reg = false,
    },
    on_replay = {
    set_reg = false,
    },
    keys = {
    telescope = {
        i = {
        select = '<cr>',
        paste = '<c-p>',
        paste_behind = '<c-k>',
        replay = '<c-q>',  -- replay a macro
        delete = '<c-d>',  -- delete an entry
        custom = {},
        },
        n = {
        select = '<cr>',
        paste = 'p',
        paste_behind = 'P',
        replay = 'q',
        delete = 'd',
        custom = {},
        },
    },
    fzf = {
        select = 'default',
        paste = 'ctrl-p',
        paste_behind = 'ctrl-k',
        custom = {},
    },
    },
})
require("telescope").load_extension "neoclip"

-- bookmarks
--[[
require('telescope').setup {
  extensions = {
    bookmarks = {
      -- Available: 'brave', 'buku', 'chrome', 'chrome_beta', 'edge', 'safari', 'firefox', 'vivaldi'
      selected_browser = 'firefox',

      -- Either provide a shell command to open the URL
      url_open_command = 'open',

      -- Or provide the plugin name which is already installed
      -- Available: 'vim_external', 'open_browser'
      url_open_plugin = nil,

      -- Show the full path to the bookmark instead of just the bookmark name
      full_path = true,

      -- Provide a custom profile name for Firefox
      firefox_profile_name = 'default-release',
    },
  }
}
require('telescope').load_extension('bookmarks')
--]]

require("telescope").load_extension "ui-select"

-- keymaps --
--
local key_map = vim.api.nvim_set_keymap

-- telescope builtins --

key_map(
  "n",
  "<leader>ft",
  [[<Cmd>lua require'telescope.builtin'.builtin{}<CR>]],
  { noremap = true, silent = true }
)

key_map(
  "n",
  "<leader>fb",
  [[<Cmd>lua require'telescope.builtin'.buffers{}<CR>]],
  { noremap = true, silent = true }
)

key_map(
  "n",
  "<leader>ff",
  [[<Cmd>lua require'telescope.builtin'.find_files({ hidden = true })<CR>]],
  { noremap = true, silent = true }
)

key_map(
  "n",
  "<leader>fo",
  [[<Cmd>lua require'telescope.builtin'.oldfiles{}<CR>]],
  { noremap = true, silent = true }
)

key_map(
  "n",
  "<leader>fg",
  [[<Cmd>lua require'telescope.builtin'.git_files{}<CR>]],
  { noremap = true, silent = true }
)

key_map(
  "n",
  "<leader>fk",
  [[<Cmd>lua require'telescope.builtin'.keymaps{}<CR>]],
  { noremap = true, silent = true }
)

key_map(
  "n",
  "<leader>fr",
  [[<Cmd>lua require'telescope.builtin'.registers{}<CR>]],
  { noremap = true, silent = true }
)

key_map(
  "n",
  "<leader>fm",
  [[<Cmd>lua require'telescope.builtin'.marks{}<CR>]],
  { noremap = true, silent = true }
)

key_map(
  "n",
  "<leader>'",
  [[<Cmd>lua require'telescope.builtin'.marks{}<CR>]],
  { noremap = true, silent = true }
)

key_map(
  "n",
  "<leader>/",
  [[<Cmd>lua require'telescope.builtin'.current_buffer_fuzzy_find{}<CR>]],
  { noremap = true, silent = true }
)

key_map(
  "n",
  "<leader>rg",
  [[<Cmd>lua require'telescope.builtin'.live_grep{}<CR>]],
  { noremap = true, silent = true }
)

key_map(
  "n",
  "<leader>fc",
  [[<Cmd>lua require'telescope.builtin'.colorscheme{}<CR>]],
  { noremap = true, silent = true }
)

-- Extensions keymaps --

-- neoclip
key_map(
  "n",
  "<leader>fy",
  [[<Cmd>lua require('telescope').extensions.neoclip.default()<CR>]],
  { noremap = true, silent = true }
)
