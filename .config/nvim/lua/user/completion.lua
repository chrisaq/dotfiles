-- from: https://github.com/VonHeikemen/lsp-zero.nvim/wiki/Under-the-hood
---
-- luasnip
---
local luasnip = require('luasnip')
require('luasnip.loaders.from_vscode').load()

luasnip.config.set_config({
  region_check_events = 'InsertEnter',
  delete_check_events = 'InsertLeave'
})

---
-- cmp
---
local lspkind = require('lspkind')

vim.o.completeopt = "menuone,noselect"

local cmp = require('cmp')

cmp.setup {
  completion = {
    completeopt = 'menu,menuone,noinsert'
  },
  snippet = {
    expand = function(args)
      luasnip.lsp_expand(args.body)
    end,
  },
  sources = {
    {name = 'path'},
    {name = 'nvim_lsp', keyword_length = 3},
    {name = 'buffer', keyword_length = 3},
    {name = 'luasnip', keyword_length = 2},
    {name = 'cmp_tabnine'},
  },
  window = {
    documentation = vim.tbl_deep_extend(
      'force',
      cmp.config.window.bordered(),
      {
        max_height = 15,
        max_width = 60,
      }
    )
  },
  formatting = {
    format = lspkind.cmp_format({
      mode = 'symbol_text', -- show only symbol annotations
      maxwidth = 50, -- prevent the popup from showing more than provided characters (e.g 50 will not show more than 50 characters)
      -- The function below will be called before any actual modifications from lspkind
      -- so that you can provide more controls on popup customization. (See [#30](https://github.com/onsails/lspkind-nvim/pull/30))
      -- before = function (entry, vim_item)
      --   ...
      --   return vim_item
      -- end
      })
    --  -- OLD config
    -- fields = {'abbr', 'menu', 'kind'},
    -- format = function(entry, item)
    --   local short_name = {
    --     nvim_lsp = 'LSP',
    --     nvim_lua = 'nvim'
    --   }
    --
    --   local menu_name = short_name[entry.source.name] or entry.source.name
    --
    --   item.menu = string.format('[%s]', menu_name)
    --   return item
    -- end,
  },
  mapping = {
    -- confirm selection
    ['<CR>'] = cmp.mapping.confirm({select = true}),

    -- navigate items on the list
    ['<Up>'] = cmp.mapping.select_prev_item(cmp_select_opts),
    ['<Down>'] = cmp.mapping.select_next_item(cmp_select_opts),

    -- scroll up and down in the completion documentation
    ['<C-f>'] = cmp.mapping.scroll_docs(5),
    ['<C-u>'] = cmp.mapping.scroll_docs(-5),

    -- toggle completion
    ['<C-e>'] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.close()
        fallback()
      else
        cmp.complete()
      end
    end),

    -- go to next placeholder in the snippet
    ['<C-d>'] = cmp.mapping(function(fallback)
      if luasnip.jumpable(1) then
        luasnip.jump(1)
      else
        fallback()
      end
    end, {'i', 's'}),

    -- go to previous placeholder in the snippet
    ['<C-b>'] = cmp.mapping(function(fallback)
      if luasnip.jumpable(-1) then
        luasnip.jump(-1)
      else
        fallback()
      end
    end, {'i', 's'}),

    -- when menu is visible, navigate to next item
    -- when line is empty, insert a tab character
    -- else, activate completion
    ['<Tab>'] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_next_item(cmp_select_opts)
      elseif util.check_back_space() then
        fallback()
      else
        cmp.complete()
      end
    end, {'i', 's'}),

    -- when menu is visible, navigate to previous item on list
    -- else, revert to default behavior
    ['<S-Tab>'] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_prev_item(cmp_select_opts)
      else
        fallback()
      end
    end, {'i', 's'}),
  }
}
