-- Format on save and linters
-- Got the below from here:
-- https://github.com/hendrikmi/dotfiles/blob/main/nvim/lua/plugins/none-ls.lua
-- https://www.youtube.com/watch?v=IobijoroGE0&list=PLJ5ehGIB3y_6aMN11anuo5VPJPAzSlazD&index=44
return {
    "nvimtools/none-ls.nvim",
    dependencies = {
        "nvimtools/none-ls-extras.nvim",
        "jayp0521/mason-null-ls.nvim", -- ensure dependencies are installed
    },
    config = function()
        local null_ls = require("null-ls")
        local formatting = null_ls.builtins.formatting -- to setup formatters
        local diagnostics = null_ls.builtins.diagnostics -- to setup linters

        -- list of formatters & linters for mason to install
        require("mason-null-ls").setup({
            ensure_installed = {
                -- "prettier", -- ts/js formatter
                "stylua", -- lua formatter
                "djlint",
                -- "eslint_d", -- ts/js linter
                "shfmt",
                "ruff",
            },
            -- auto-install configured formatters & linters (with null-ls)
            automatic_installation = true,
        })

        local sources = {
            -- formatting.prettier.with({ filetypes = { "html", "json", "yaml", "markdown" } }),
            formatting.stylua,
            formatting.djlint.with({
                extra_args = { "--reformat" },
            }),
            formatting.shfmt.with({ args = { "-i", "4" } }),
            formatting.terraform_fmt,
            require("none-ls.formatting.ruff").with({ extra_args = { "--extend-select", "I" } }),
            require("none-ls.formatting.ruff_format"),
            null_ls.builtins.diagnostics.djlint,
            null_ls.builtins.formatting.djlint,
        }

        local augroup = vim.api.nvim_create_augroup("LspFormatting", {})
        null_ls.setup({
            -- debug = true, -- Enable debug mode. Inspect logs with :NullLsLog.
            sources = sources,
            -- you can reuse a shared lspconfig on_attach callback here
            on_attach = function(client, bufnr)
                if client.supports_method("textDocument/formatting") then
                    vim.api.nvim_clear_autocmds({ group = augroup, buffer = bufnr })
                    vim.api.nvim_create_autocmd("BufWritePre", {
                        group = augroup,
                        buffer = bufnr,
                        callback = function()
                            vim.lsp.buf.format({ async = false })
                        end,
                    })
                end
            end,
        })
    end,
}
