return {
  -- Completion
  {
    "hrsh7th/nvim-cmp",
    event = "InsertEnter",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-path",
      {
        "L3MON4D3/LuaSnip",
        version = "2.*",
        build = "make install_jsregexp",
      },
      "hrsh7th/cmp-nvim-lua",
      "saadparwaiz1/cmp_luasnip",
      "rafamadriz/friendly-snippets",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "petertriho/cmp-git",
      "hrsh7th/cmp-nvim-lsp-signature-help",
    },
    config = function()
      local cmp = require("cmp")
      local cmp_autopairs = require("nvim-autopairs.completion.cmp")
      local luasnip = require("luasnip")
      require("luasnip.loaders.from_vscode").lazy_load()
      cmp.setup {
        -- enable only if characters on line, not only whitespace
        -- enabled = function()
        --   local line = vim.api.nvim_get_current_line()
        --   local col = vim.fn.col('.')
        --   local before_cursor = string.sub(line, 1, col - 1)
        --   -- disable if only whitespace before cursor
        --   return not before_cursor:match("^%s*$")
        -- end,
        experimental = {
          ghost_text = true,
        },
        window = {
          completion = {
            winhighlight = "Normal:Pmenu,FloatBorder:Pmenu,Search:None",
            col_offset = -3,
            side_padding = 0,
            border = 'rounded',
            scrollbar = '║'
          },
          documentation = { -- no border; native-style scrollbar
            border = nil,
            scrollbar = '',
          },
        },
        -- trying to get cmp to not select any items unless specifically chosen
        preselect = cmp.PreselectMode.None,
        formatting = {
          format = function(_, vim_item)
            local icon, hl = MiniIcons.get("lsp", vim_item.kind)
            vim_item.kind = icon .. " " .. vim_item.kind
            vim_item.kind_hl_group = hl
            return vim_item
          end,
        },
        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },
        confirmation = { completeopt = 'menu,menuone,noinsert' },
        mapping = cmp.mapping.preset.insert({
        -- mapping = cmp.mapping({
          -- CQmapping: cmp-insert: C-d -- cmp.mapping.scroll_docs(-4), -- scroll down in documentation
          ["<C-d>"] = cmp.mapping.scroll_docs(-4), -- scroll down in documentation
          -- CQmapping: cmp-insert: C-u -- cmp.mapping.scroll_docs(4), -- scroll up in documentation
          ["<C-u>"] = cmp.mapping.scroll_docs(4), -- scroll up in documentation
          -- CQmapping: insert: C-e -- cmp open completion menu
          ["<C-e>"] = cmp.mapping.complete(),
          -- ["<C-e>"] = cmp.mapping.complete({
          --   reason = cmp.ContextReason.Auto,
          -- }),
          -- CQmapping: cmp-insert: C-c -- cmp.abort -- abort completion
          ["<C-c>"] = cmp.mapping.abort(),
          -- CQmapping: cmp-insert: C-g -- cmp.confirm -- confirm completion
          -- ["<CR>"] = cmp.mapping.confirm {
          ["<C-f>"] = cmp.mapping.confirm {
            behavior = cmp.ConfirmBehavior.Replace,
            select = true
          },
          ["<Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_next_item()
            elseif luasnip.expand_or_jumpable() then
              luasnip.expand_or_jump()
            else
              fallback()
            end
          end, { "i", "s" }),
          ["<S-Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_prev_item()
            elseif luasnip.jumpable(-1) then
              luasnip.jump(-1)
            else
              fallback()
            end
          end, { "i", "s" }),
        }),
        sources = {
          { name = "nvim_lsp" },
          { name = "copilot"},
          { name = "supermaven" },
          { name = "codeium" },
          { name = "luasnip" },
          { name = "buffer" },
          { name = "nvim_lua" },
          { name = "nvim_lsp_signature_help" },
          { name = "path"}
        },
        view = { entries = { name = "custom", selection_order = "near_cursor" } },
      }

      cmp.setup.filetype('gitcommit', {
          sources = cmp.config.sources(
          {{ name = 'git' }},
          {{ name = 'buffer' }}
        )
      })
      require("cmp_git").setup()
      cmp.event:on(
        'confirm_done',
        cmp_autopairs.on_confirm_done()
      )
      cmp.setup.cmdline(':', {
        confirmation = { completeopt = 'menu,menuone,noinsert' },
        sources = {
          { name = 'cmdline' },
          { name = 'cmdline_history' },
          { name = 'path'}
        }
      })
      cmp.setup.cmdline('/', {
        sources = {
          { name = 'buffer' }
        },
      })
    end,
  },
}
