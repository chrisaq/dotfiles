-- lsp setup
-- Set Default Prefix.
-- Note: You can set a prefix per lsp server in the lv-globals.lua file
vim.lsp.handlers["textDocument/publishDiagnostics"] = vim.lsp.with(vim.lsp.diagnostic.on_publish_diagnostics, {
	virtual_text = {
		prefix = "",
		spacing = 0,
	},
	signs = true,
	underline = true,
})

vim.cmd([[ command! Format execute 'lua vim.lsp.buf.formatting_sync()' ]])

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

---
-- lspkind
---
require("lspkind").init({
	-- defines how annotations are shown
	-- default: symbol
	-- options: 'text', 'text_symbol', 'symbol_text', 'symbol'
	mode = "symbol_text",

	-- default symbol map
	-- can be either 'default' (requires nerd-fonts font) or
	-- 'codicons' for codicon preset (requires vscode-codicons font)
	--
	-- default: 'default'
	preset = "default",

	-- override preset symbols
	--
	-- default: {}
	symbol_map = {
		Text = "",
		Method = "",
		Function = "",
		Constructor = "",
		Field = "ﰠ",
		Variable = "",
		Class = "ﴯ",
		Interface = "",
		Module = "",
		Property = "ﰠ",
		Unit = "塞",
		Value = "",
		Enum = "",
		Keyword = "",
		Snippet = "",
		Color = "",
		File = "",
		Reference = "",
		Folder = "",
		EnumMember = "",
		Constant = "",
		Struct = "פּ",
		Event = "",
		Operator = "",
		TypeParameter = "",
	},
})
-- MOVING TO MASON
--

---
-- Utility functions
---
--[[

-- from: https://github.com/VonHeikemen/lsp-zero.nvim/wiki/Under-the-hood
--local util = {}
--]]

--[[

_G.User = {}

local suggest_state_file = vim.fn.stdpath('data') .. '/lsp-suggest.info.json'
local suggest_state = {ok = false}

function User.suggest_server()
  local path = suggest_state_file
  local ft = vim.bo.filetype

  if vim.bo.buftype == 'prompt' or ft == '' or ft == nil then
    return
  end

  local state = nil

  if vim.fn.filereadable(path) == 0 then
    suggest_state = util.create_state()
    state = suggest_state
  else
    state = suggest_state.ok and suggest_state 
      or vim.json.decode(util.read_file(path))
  end

  if state.filetypes[ft] then
    return
  end

  state.filetypes[ft] = true
  util.write_file(path, vim.json.encode(state))

  vim.cmd('LspInstall')
end

util.create_state = function()
  local path = suggest_state_file
  local defaults = {
    ok = true,
    servers = {},
    filetypes = {
      ['lsp-installer'] = true,
      qf = true
    },
  }

  util.write_file(path, vim.json.encode(defaults))
  return defaults
end

util.update_state = function(server)
  local path = suggest_state_file
  local state = nil

  if vim.fn.filereadable(path) == 0 then
    state = util.create_state()
  else
    state = suggest_state.ok and suggest_state 
      or vim.json.decode(util.read_file(path))
  end

  if state.servers[server.name] then
    return
  end

  state.servers[server.name] = true

  local fts = server:get_supported_filetypes()

  for _, ft in ipairs(fts) do
    state.filetypes[ft] = true
  end

  util.write_file(path, vim.json.encode(state))
end
--]]

--vim.cmd([[
--  augroup user_cmds
--    autocmd!
--    autocmd FileType * lua vim.defer_fn(User.suggest_server, 5)
--  augroup END
--]])
