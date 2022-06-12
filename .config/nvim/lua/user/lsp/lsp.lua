-- lsp setup
-- Set Default Prefix.
-- Note: You can set a prefix per lsp server in the lv-globals.lua file
vim.lsp.handlers["textDocument/publishDiagnostics"] = vim.lsp.with(
  vim.lsp.diagnostic.on_publish_diagnostics, {
    virtual_text = {
      prefix = "",
      spacing = 0,
    },
    signs = true,
    underline = true,
  }
)

---
-- lspkind
---

require('lspkind').init({
    -- defines how annotations are shown
    -- default: symbol
    -- options: 'text', 'text_symbol', 'symbol_text', 'symbol'
    mode = 'symbol_text',

    -- default symbol map
    -- can be either 'default' (requires nerd-fonts font) or
    -- 'codicons' for codicon preset (requires vscode-codicons font)
    --
    -- default: 'default'
    preset = 'default',

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
      TypeParameter = ""
    },
})

---
-- lsp_installer
---

local lsp_installer = require("nvim-lsp-installer")

-- Register a handler that will be called for all installed servers.
-- Alternatively, you may also register handlers on specific server instances instead (see example below).
lsp_installer.on_server_ready(function(server)
    local opts = {}

    -- (optional) Customize the options passed to the server
    -- if server.name == "tsserver" then
    --     opts.root_dir = function() ... end
    -- end

    -- This setup() function is exactly the same as lspconfig's setup function.
    -- Refer to https://github.com/neovim/nvim-lspconfig/blob/master/doc/server_configurations.md
    server:setup(opts)
end)

---
-- Suggest servers
---

-- from: https://github.com/VonHeikemen/lsp-zero.nvim/wiki/Under-the-hood
--local util = {}
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

vim.cmd([[
  augroup user_cmds
    autocmd!
    autocmd FileType * lua vim.defer_fn(User.suggest_server, 5)
  augroup END
]])


--[[
-- -- uncomment below to enable nerd-font based icons for diagnostics in the
-- -- gutter, see:
-- -- https://github.com/neovim/nvim-lspconfig/wiki/UI-customization#change-diagnostic-symbols-in-the-sign-column-gutter
local signs = { Error = " ", Warn = " ", Hint = " ", Info = " " }

for type, icon in pairs(signs) do
   local hl = "DiagnosticSign" .. type
   vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = "" })
end

-- symbols for autocomplete
vim.lsp.protocol.CompletionItemKind = {
    "   (Text) ",
    "   (Method)",
    "   (Function)",
    "   (Constructor)",
    " ﴲ  (Field)",
    "[] (Variable)",
    "   (Class)",
    " ﰮ  (Interface)",
    "   (Module)",
    " 襁 (Property)",
    "   (Unit)",
    "   (Value)",
    " 練 (Enum)",
    "   (Keyword)",
    "   (Snippet)",
    "   (Color)",
    "   (File)",
    "   (Reference)",
    "   (Folder)",
    "   (EnumMember)",
    " ﲀ  (Constant)",
    " ﳤ  (Struct)",
    "   (Event)",
    "   (Operator)",
    "   (TypeParameter)"
}
--]]

-- local function documentHighlight(client, bufnr)
--     -- Set autocommands conditional on server_capabilities
--     if client.resolved_capabilities.document_highlight then
--         vim.api.nvim_exec(
--             [[
--       hi LspReferenceRead cterm=bold ctermbg=red guibg=#464646
--       hi LspReferenceText cterm=bold ctermbg=red guibg=#464646
--       hi LspReferenceWrite cterm=bold ctermbg=red guibg=#464646
--       augroup lsp_document_highlight
--         autocmd! * <buffer>
--         autocmd CursorHold <buffer> lua vim.lsp.buf.document_highlight()
--         autocmd CursorMoved <buffer> lua vim.lsp.buf.clear_references()
--       augroup END
--     ]],
--             false
--         )
--     end
-- end
--
