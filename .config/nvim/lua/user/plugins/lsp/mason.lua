return {
  "williamboman/mason.nvim",
  dependencies = {
    "williamboman/mason-lspconfig.nvim",
    "WhoIsSethDaniel/mason-tool-installer.nvim",
  },
  config = function()
    -- import mason
    local mason = require("mason")

    -- import mason-lspconfig
    local mason_lspconfig = require("mason-lspconfig")

    local mason_tool_installer = require("mason-tool-installer")
    local key_map = vim.keymap.set
    key_map("n", "<F2>", "<CMD>Mason<CR>", { desc = "Mason" })
    -- enable mason and configure icons
    mason.setup({
      ui = {
        border = "rounded",
        icons = {
          package_installed = "✓",
          package_pending = "➜",
          package_uninstalled = "✗",
        },
      },
    })

    mason_lspconfig.setup({
      -- list of servers for mason to install
      ensure_installed = {
        "rust_analyzer",
        "bashls",
        "pyright",
        "cssls",
        "gopls",
        "html",
        "jsonls", -- language servers
        "jsonnet_ls",
        "zk@v0.10.1",
        "taplo",
        "terraformls",
        "tflint",
        "vuels",
        "yamlls",
        "eslint",
      },
    })

    mason_tool_installer.setup({
      ensure_installed = {
        "prettier", -- prettier formatter
        "stylua", -- lua formatter
        "isort", -- python formatter
        "black", -- python formatter
        "pylint",
        "eslint_d",
      },
    })
  end,
}
