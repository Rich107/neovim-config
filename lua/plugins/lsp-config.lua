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
			require("mason-lspconfig").setup({
				ensure_installed = {
					-- "tsserver",
					-- "typescript-language-server",
					"html",
					"tailwindcss",
					"svelte",
					"lua_ls",
					"graphql",
					"emmet_ls",
					"prismals",
					"volar",
					"docker_compose_language_service",
					"dockerls",
					"biome",
					"ruff",
					"terraformls",
					-- "mypy",
					"pyright",
				},
			})
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
				["emmet_ls"] = function()
					-- configure emmet language server
					lspconfig["emmet_ls"].setup({
						capabilities = capabilities,
						filetypes = {
							"html",
							"typescriptreact",
							"javascriptreact",
							"css",
							"sass",
							"scss",
							"less",
							"vue",
							"svelte",
						},
					})
				end,
				["pyright"] = function()
					-- configure emmet language server
					lspconfig["pyright"].setup({
						capabilities = capabilities,
						on_attach = function(client, bufnr)
							-- Set up keybindings for code actions, if needed
							vim.api.nvim_buf_set_keymap(
								bufnr,
								"n",
								"<leader>ca",
								"<cmd>lua vim.lsp.buf.code_action()<CR>",
								-- { noremap = true, silent = true }
								{ noremap = true }
							)
						end,
						filetypes = { "python" },
					})
				end,
				-- ["terraformls"] = function()
				-- 	lspconfig["terraformls"].setup({
				-- 		capabilities = capabilities,
				-- 		filetypes = { "terraform", "hcl", "tf" }, -- Ensure these are correctly set
				-- 		on_attach = function(client, bufnr)
				-- 			-- Ensure commentstring is set correctly
				-- 			vim.api.nvim_buf_set_option(bufnr, "commentstring", "# %s")
				-- 		end,
				-- 	})
				-- end,
				["terraformls"] = function()
					lspconfig["terraformls"].setup({
						capabilities = capabilities,
						filetypes = { "terraform", "hcl", "tf" }, -- Ensure these are correctly set
						root_dir = require("lspconfig").util.root_pattern("*.tf"),
						on_attach = function(client, bufnr)
							-- Ensure commentstring is set correctly
							vim.api.nvim_buf_set_option(bufnr, "commentstring", "# %s")
						end,
					})
				end,
				-- ["terraform-lsp"] = function()
				-- 	lspconfig["terraform-lsp"].setup({
				-- 		capabilities = capabilities,
				-- 		filetypes = { "terraform", "hcl", "tf" }, -- Ensure these are correctly set
				-- 		on_attach = function(client, bufnr)
				-- 			-- Ensure commentstring is set correctly
				-- 			vim.api.nvim_buf_set_option(bufnr, "commentstring", "# %s")
				-- 		end,
				-- 	})
				-- end,
				-- ["python_ls"] = function()
				-- 	-- configure emmet language server
				-- 	lspconfig["python_ls"].setup({
				-- 		capabilities = capabilities,
				-- 		on_attach = cmp_nvim_lsp.on_attach,
				-- 		filetypes = { "python" },
				-- 	})
				-- end,
				["lua_ls"] = function()
					-- configure lua server (with special settings)
					lspconfig["lua_ls"].setup({
						capabilities = capabilities,
						settings = {
							Lua = {
								-- make the language server recognize "vim" global
								diagnostics = {
									globals = { "vim" },
								},
								completion = {
									callSnippet = "Replace",
								},
							},
						},
					})
				end,
				["volar"] = function()
					require("lspconfig").volar.setup({
						-- NOTE: Uncomment to enable volar in file types other than vue.
						-- (Similar to Takeover Mode)
						-- IMPORTANT: Make sure tsserver has a tsserver.config.json and tsserver.json file for your project!
						-- filetypes = { "vue", "javascript", "typescript", "javascriptreact", "typescriptreact", "json" },

						-- NOTE: Uncomment to restrict Volar to only Vue/Nuxt projects. This will enable Volar to work alongside other language servers (tsserver).

						-- root_dir = require("lspconfig").util.root_pattern(
						--   "vue.config.js",
						--   "vue.config.ts",
						--   "nuxt.config.js",
						--   "nuxt.config.ts"
						-- ),
						init_options = {
							vue = {
								hybridMode = false,
							},
							-- NOTE: This might not be needed. Uncomment if you encounter issues.

							typescript = {
								tsdk = vim.fn.getcwd() .. "/node_modules/typescript/lib",
							},
						},
						settings = {
							typescript = {
								inlayHints = {
									enumMemberValues = {
										enabled = true,
									},
									functionLikeReturnTypes = {
										enabled = true,
									},
									propertyDeclarationTypes = {
										enabled = true,
									},
									parameterTypes = {
										enabled = true,
										suppressWhenArgumentMatchesName = true,
									},
									variableTypes = {
										enabled = true,
									},
								},
							},
						},
					})
				end,
				["tsserver"] = function()
					local mason_packages = vim.fn.stdpath("data") .. "/mason/packages"
					local volar_path = mason_packages .. "/vue-language-server/node_modules/@vue/language-server"

					require("lspconfig").tsserver.setup({
						-- NOTE: To enable hybridMode, change HybrideMode to true above and uncomment the following filetypes block.

						-- filetypes = { "typescript", "javascript", "javascriptreact", "typescriptreact", "vue" },
						init_options = {
							plugins = {
								{
									name = "@vue/typescript-plugin",
									location = volar_path,
									languages = { "vue" },
								},
							},
						},
						settings = {
							typescript = {
								inlayHints = {
									includeInlayParameterNameHints = "all",
									includeInlayParameterNameHintsWhenArgumentMatchesName = true,
									includeInlayFunctionParameterTypeHints = true,
									includeInlayVariableTypeHints = true,
									includeInlayVariableTypeHintsWhenTypeMatchesName = true,
									includeInlayPropertyDeclarationTypeHints = true,
									includeInlayFunctionLikeReturnTypeHints = true,
									includeInlayEnumMemberValueHints = true,
								},
							},
						},
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
					vim.keymap.set("n", "<leader>cn", vim.lsp.buf.rename, {})
				end,
			})
		end,
	},
}
