local null_ls = require("null-ls")
local utils = require("null-ls.utils")
local formatting = null_ls.builtins.formatting

null_ls.setup({
    debug = true,
    root_dir = utils.root_pattern("composer.json", "package.json", "Makefile", ".git"), -- Add composer
    diagnostics_format = "#{m} (#{c}) [#{s}]", -- Makes PHPCS errors more readeable
    sources = {
       	formatting.prettier.with({ extra_args = { "--no-semi", "--single-quote", "--jsx-single-quote" } }),
		formatting.black.with({ extra_args = { "--fast" } }),
		formatting.stylua,
        null_ls.builtins.completion.spell, -- You still need to execute `:set spell`
        null_ls.builtins.diagnostics.markdownlint, -- Install it with `npm i -g markdownlint-cli`
        null_ls.builtins.diagnostics.phpcs.with({ -- Use the local installation first
            prefer_local = "vendor/bin",
        }),
        null_ls.builtins.formatting.markdownlint,
        null_ls.builtins.formatting.phpcbf.with({
            prefer_local = "vendor/bin",
        }),
    },
})

