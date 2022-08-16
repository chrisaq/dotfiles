-- from: https://github.com/VonHeikemen/lsp-zero.nvim/wiki/Under-the-hood
--
---
-- cmp
---
local lspkind = require('lspkind')

-- vim.o.completeopt = "menuone,noselect"
vim.opt.completeopt = {'menu', 'menuone', 'noselect'}

local cmp = require('cmp')

cmp.setup {
  completion = {
    completeopt = 'menu,menuone,noinsert'
  },
  sources = {
    {name = 'nvim_lsp', keyword_length = 3},
    {name = 'path'},
  }, {
    {name = 'buffer', keyword_length = 5},
  },
  experimental = { ghost_text = true },
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
    --['<CR>'] = cmp.mapping.confirm({select = true}),
    ['<C-Space>'] = cmp.mapping.confirm({select = true}),

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

_G.util = {}

local uv = vim.loop

util.check_back_space = function()
  local col = vim.fn.col('.') - 1
  if col == 0 or vim.fn.getline('.'):sub(col, col):match('%s') then
    return true
  else
    return false
  end
end

util.write_file = function(path, contents)
  local fd = assert(uv.fs_open(path, 'w', 438))
  uv.fs_write(fd, contents, -1)
  assert(uv.fs_close(fd))
end

util.read_file = function(path)
  local fd = assert(uv.fs_open(path, 'r', 438))
  local fstat = assert(uv.fs_fstat(fd))
  local contents = assert(uv.fs_read(fd, fstat.size, 0))
  assert(uv.fs_close(fd))
  return contents
end


