-- Use 2 spaces instead of 4 for lua
local o = vim.opt_local
o.shiftwidth = 2
o.tabstop = 2
o.expandtab = true
o.smarttab = true

vim.api.nvim_create_autocmd('FileType', {
  pattern = 'markdown',
  callback = function(args)
    vim.lsp.start({
      name = 'iwes',
      cmd = {'iwes'},
      root_dir = vim.fs.root(args.buf, {'.iwe' }),
      flags = {
        debounce_text_changes = 500
      }
    })
  end,
})
