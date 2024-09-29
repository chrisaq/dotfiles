-- leader
vim.g.mapleader = " "

-- Mappings for core nvim
local key_map = vim.keymap.set
local cmd = vim.cmd
--
-- inc/dec numbers right of cursor using -/+
-- currently - is used by oil
-- key_map("n", "+", "<C-a>", { noremap = true, silent = true })
-- key_map("n", "-", "<C-x>", { noremap = true, silent = true })

-- Seriously, guys. It's not like :W is bound to anything anyway.
cmd(":command! W :w<CR>")
cmd(":command! Q :q<CR>")

-- sudo write this
-- key_map("", "", "", { noremap = true, silent = true })
key_map("c", "W!", [[<Cmd>w !sudo tee % >/dev/null<CR>]], { noremap = true, silent = true })
-- cmap W! w !sudo tee % >/dev/null
-- for when we forget to use sudo to open/edit a file
key_map("c", "w!!", [[<Cmd>w !sudo tee % >/dev/null<CR>]], { noremap = true, silent = true })

key_map("n", "<leader>bn", ":enew<CR>", { noremap = true, silent = true, desc = "New buffer"})
key_map("n", "<leader>bx", ":new<CR>", { noremap = true, silent = true, desc = "Split new buffer"})
key_map("n", "<leader>bd", ":Bdelete<CR>", { noremap = true, silent = true, desc = "Close buffer"})
key_map("n", "<leader>l", ":bnext<CR>", { noremap = true, silent = true, desc = "Next buffer"})
key_map("n", "<leader>h", ":bprevious<CR>", { noremap = true, silent = true, desc = "Previous buffer"})

-- close all buffers except current
cmd(":command! BufOnly execute '%bdelete|edit #|normal `\"'")

-- CQmapping: normal: <leader>q -- Open diagnostic [Q]uickfix list
-- Diagnostic keymaps
key_map("n", "<leader>q", vim.diagnostic.setloclist, { noremap = true, silent = true, desc = "Open diagnostic [Q]uickfix list" })
-- key_map("n", "<leader><space>", ":nohlsearch<CR>", { noremap = true, silent = true, desc = "Clear search highlights"})
key_map('n', '<Esc>', '<cmd>nohlsearch<CR>')
key_map("n",  "<leader>v", '"+gP', { noremap = true, silent = true, desc = "Paste from clipboard" }) -- Paste from clipboard
-- key_map("n",  "<leader>q", ":q<CR>", { noremap = true, silent = true, desc = "Quit current window" }) -- Quit current window
key_map("n",  "<leader>Q", ":qall<CR>", { noremap = true, silent = true, desc = "Quit all windows" }) -- Quit all windows
-- key_map("n", "<leader><BS>", [[:%s/\s\+$//<cr>:let @/=''<CR>]], { noremap = true, silent = true, desc = "Remove trailing whitespace"}) -- Remove trailing whitespace on <leader>backspace

