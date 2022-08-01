local opt = vim.opt -- to set options
opt.termguicolors = true
opt.background = "dark"

vim.cmd('colorscheme catppuccin')
-- vim.cmd('colorscheme solarized')
vim.g.solarized_diffmode = 'normal'
vim.g.solarized_visibility = 'normal'
-- To enable transparency
if vim.fn.has('gui_running') == 0 then
    vim.g.solarized_termtrans = 0
else
    vim.g.solarized_termtrans = 1
end


