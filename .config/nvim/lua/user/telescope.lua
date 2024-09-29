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
      theme = "ivy",
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
  pickers = {
    find_files = {
      find_command = {'rg', '--files', '--hidden', '-g', '!.git'},
      layout_config = {
        height = 0.70
      }
    }
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


-- file browser
require("telescope").load_extension "file_browser"

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
local key_map = vim.keymap.set

-- telescope builtins --
local builtin = require('telescope.builtin')
key_map("n", "<leader>ft", builtin.builtin, { noremap = true, silent = true, desc = "Telescope builtin" })
key_map("n", "<leader>fb", builtin.buffers, { noremap = true, silent = true, desc = "Telescope buffers" })
key_map("n", "<leader>ff", function() builtin.find_files({ hidden = true })end, { noremap = true, silent = true, desc = "Telescope find_files" })
key_map("n", "<leader>fo", builtin.oldfiles, { noremap = true, silent = true, desc = "Telescope oldfiles" })
key_map("n", "<leader>fg", builtin.git_files, { noremap = true, silent = true, desc = "Telescope git_files" })
key_map("n", "<leader>fk", builtin.keymaps, { noremap = true, silent = true, desc = "Telescope keymaps" })
key_map("n", "<leader>fr", builtin.registers, { noremap = true, silent = true, desc = "Telescope registers" })
key_map("n", "<leader>fm", builtin.marks, { noremap = true, silent = true, desc = "Telescope marks" })
key_map("n", "<leader>'", builtin.marks, { noremap = true, silent = true, desc = "Telescope marks" })
key_map("n", "<leader>/", builtin.current_buffer_fuzzy_find, { noremap = true, silent = true, desc = "Telescope current_buffer_fuzzy_find" })
key_map("n", "<leader>rg", builtin.live_grep, { noremap = true, silent = true, desc = "Telescope live_grep" })
key_map("n", "<leader>fc", builtin.colorscheme, { noremap = true, silent = true, desc = "Telescope colorscheme" })

-- Extensions keymaps --

-- neoclip
key_map("n", "<leader>fy", [[<Cmd>lua require('telescope').extensions.neoclip.default()<CR>]], { noremap = true, silent = true, desc = "Telescope neoclip" })

-- file_browser
key_map("n", "<leader>fd", ":Telescope file_browser<CR>", { noremap = true, desc = "Telescope file_browser" })

------------------------------------------------------------------------------
-- gp.nvim picker for models - https://github.com/Robitx/gp.nvim/issues/187
local pickers = require 'telescope.pickers'
local finders = require 'telescope.finders'
local actions = require 'telescope.actions'
local action_state = require 'telescope.actions.state'
local conf = require('telescope.config').values

local models = function(opts)
  local buf = vim.api.nvim_get_current_buf()
  local file_name = vim.api.nvim_buf_get_name(buf)
  local is_chat = require('gp').not_chat(buf, file_name) == nil

  opts = opts or {}
  pickers
    .new(opts, {
      prompt_title = 'Models',
      finder = finders.new_table {
        results = is_chat and require('gp')._chat_agents or require('gp')._command_agents,
      },
      sorter = conf.generic_sorter(opts),
      attach_mappings = function(prompt_bufnr)
        actions.select_default:replace(function()
          local selection = action_state.get_selected_entry()
          actions.close(prompt_bufnr)
          require('gp').cmd.Agent { args = selection[1] }
        end)
        return true
      end,
    })
    :find()
end

vim.keymap.set('n', '<C-g>z', function()
  models(require('telescope.themes').get_dropdown {
    winblend = 10,
    previewer = false,
  })
end, {
  noremap = true,
  silent = false,
  nowait = true,
  desc = 'GPT prompt Choose Agent',
})
