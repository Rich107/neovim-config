return {
	"nvimtools/none-ls.nvim",
	config = function()
		local null_ls = require("null-ls")
		local lspconfig_util = require("lspconfig.util")

		null_ls.setup({
			autostart = true,
			root_dir = lspconfig_util.root_pattern(".git", "pyproject.toml", "setup.py", "setup.cfg"),
			sources = {
				null_ls.builtins.diagnostics.mypy,
				null_ls.builtins.diagnostics.biome,
				-- null_ls.builtins.formatting.stylua,
				-- null_ls.builtins.formatting.prettier,
				-- null_ls.builtins.diagnostics.erb_lint,
				-- null_ls.builtins.diagnostics.rubocop,
				-- null_ls.builtins.formatting.rubocop,
			},
			on_attach = function(client, bufnr)
				if client.server_capabilities.documentFormattingProvider then
					vim.api.nvim_create_autocmd("BufWritePre", {
						group = vim.api.nvim_create_augroup("LspFormatting", { clear = true }),
						buffer = bufnr,
						callback = function()
							vim.lsp.buf.format({ bufnr = bufnr })
						end,
					})
				end
			end,
		})

		vim.keymap.set("n", "<leader>gf", vim.lsp.buf.format, { desc = "format file" })
	end,
}
