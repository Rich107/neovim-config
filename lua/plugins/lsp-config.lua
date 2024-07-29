return {
	{
		"williamboman/mason.nvim",
		lazy = false,
		config = function()
			require("mason").setup()
		end,
	},
	{
		"williamboman/mason-lspconfig.nvim",
		lazy = false,
		opts = {
			auto_install = true,
		},
	},
	{
		"neovim/nvim-lspconfig",
		lazy = false,
		config = function()
			local lspconfig = require("lspconfig")

			local mason_lspconfig = require("mason-lspconfig")
			local cmp_nvim_lsp = require("cmp_nvim_lsp")

			vim.api.nvim_create_autocmd("LspAttach", {
				group = vim.api.nvim_create_augroup("UserLspConfig", {}),
				callback = function(ev)
					local map = function(keys, func, desc)
						vim.keymap.set("n", keys, func, { buffer = ev.buf, desc = "LSP: " .. desc })
					end

					-- Jump to the definition of the word under your cursor.
					--  This is where a variable was first declared, or where a function is defined, etc.
					--  To jump back, press <C-t>.
					map("gd", require("telescope.builtin").lsp_definitions, "[G]oto [D]efinition")

					-- Find references for the word under your cursor.
					map("gr", require("telescope.builtin").lsp_references, "[G]oto [R]eferences")

					vim.keymap.set("n", "<leader>k", vim.lsp.buf.hover, {})
					vim.keymap.set("n", "<leader>gr", vim.lsp.buf.references, {})
					vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, {})
				end,
			})

			local capabilities = require("cmp_nvim_lsp").default_capabilities()

			lspconfig.tsserver.setup({
				capabilities = capabilities,
			})
			lspconfig.solargraph.setup({
				capabilities = capabilities,
			})
			lspconfig.html.setup({
				capabilities = capabilities,
			})
			lspconfig.lua_ls.setup({
				capabilities = capabilities,
			})
		end,
	},
}
