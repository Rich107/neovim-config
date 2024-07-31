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
		config = function()
			require("mason-lspconfig").setup()
		end,
	},
	{
		"neovim/nvim-lspconfig",
		lazy = false,
		config = function()
			local lspconfig = require("lspconfig")
			local mason_lspconfig = require("mason-lspconfig")
			local cmp_nvim_lsp = require("cmp_nvim_lsp")

			-- Set up capabilities for cmp-nvim-lsp
			local capabilities = cmp_nvim_lsp.default_capabilities()

			-- Automatically set up LSP servers installed via mason-lspconfig
			mason_lspconfig.setup_handlers({
				function(server_name)
					lspconfig[server_name].setup({
						capabilities = capabilities,
					})
				end,
				["tsserver"] = function()
					lspconfig.tsserver.setup({
						capabilities = capabilities,
						init_options = {
							plugins = {
								{
									name = "@vue/typescript-plugin",
									location = "/usr/local/lib/node_modules/@vue/typescript-plugin",
									languages = { "javascript", "typescript", "vue" },
								},
							},
						},
						filetypes = {
							"javascript",
							"typescript",
							"vue",
						},
					})
				end,
				["volar"] = function()
					lspconfig.volar.setup({
						capabilities = capabilities,
						init_options = {
							typescript = {
								-- Ensure this path matches your TypeScript installation
								serverPath = "/Users/richardellison/PycharmProjects/pa_leaderboard_frontend/frontend_app/node_modules/typescript/lib",
							},
						},
						on_attach = function(client, bufnr)
							-- Disable other clients that might conflict
							for _, other_client in pairs(vim.lsp.get_active_clients()) do
								if other_client.name ~= "volar" and other_client.name ~= "null-ls" then
									vim.lsp.stop_client(other_client.id)
								end
							end

							-- Set up keybindings and commands specific to volar
							local map = function(keys, func, desc)
								vim.keymap.set("n", keys, func, { buffer = bufnr, desc = "LSP: " .. desc })
							end

							map("gd", require("telescope.builtin").lsp_definitions, "[G]oto [D]efinition")
							map("gr", require("telescope.builtin").lsp_references, "[G]oto [R]eferences")
							vim.keymap.set("n", "<leader>k", vim.lsp.buf.hover, {})
							vim.keymap.set("n", "<leader>gr", vim.lsp.buf.references, {})
							vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, {})
						end,
					})
				end,
			})

			-- Global keybindings and autocommands
			vim.api.nvim_create_autocmd("LspAttach", {
				group = vim.api.nvim_create_augroup("UserLspConfig", {}),
				callback = function(ev)
					local map = function(keys, func, desc)
						vim.keymap.set("n", keys, func, { buffer = ev.buf, desc = "LSP: " .. desc })
					end

					map("gd", require("telescope.builtin").lsp_definitions, "[G]oto [D]efinition")
					map("gr", require("telescope.builtin").lsp_references, "[G]oto [R]eferences")
					vim.keymap.set("n", "<leader>k", vim.lsp.buf.hover, {})
					vim.keymap.set("n", "<leader>gr", vim.lsp.buf.references, {})
					vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, {})
				end,
			})
		end,
	},
}
