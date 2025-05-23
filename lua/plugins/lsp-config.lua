return {
	{
		"williamboman/mason.nvim",
		lazy = false,
		config = function()
			require("mason").setup()
		end,
	},
	{
		"mason-org/mason-lspconfig.nvim",
		lazy = false,
		opts = {
			auto_install = true,
		},
		config = function()
			require("mason-lspconfig").setup({
				ensure_installed = {
					"ts_ls",
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
					"basedpyright",
					-- "mypy",
					-- "pyright",
				},
			})
		end,
	},
	{
		"neovim/nvim-lspconfig",
		lazy = false,
		config = function()
			local lspconfig = require("lspconfig")
			local cmp_nvim_lsp = require("cmp_nvim_lsp")

			-- Set up capabilities for cmp-nvim-lsp
			local capabilities = cmp_nvim_lsp.default_capabilities()
			capabilities.offsetEncoding = { "utf-8" }
			capabilities.positionEncodings = { "utf-8" }

			-- Automatically set up LSP servers installed via mason-lspconfig
			vim.lsp.config("emmet_ls", {
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
			vim.lsp.config("basedpyright", {
				capabilities = capabilities,
				settings = {
					python = {
						analysis = {
							autoSearchPaths = true,
							diagnosticMode = "openFilesOnly",
							useLibraryCodeForTypes = true,
							enableReachabilityAnalysis = false,
						},
					},
				},
				flags = {
					allow_incremental_sync = false,
				},
				on_attach = function(client, bufnr)
					-- Set up keybindings for code actions, if needed
					print("LSP attached: " .. client.name)
					vim.api.nvim_buf_set_keymap(
						bufnr,
						"n",
						"<leader>ca",
						"<cmd>lua vim.lsp.buf.code_action()<CR>",
						{ noremap = true }
					)
				end,
				filetypes = { "python" },
			})
			vim.lsp.config("terraformls", {
				capabilities = capabilities,
				filetypes = { "terraform", "hcl", "tf" }, -- Ensure these are correctly set
				root_dir = require("lspconfig").util.root_pattern("*.tf"),
				on_attach = function(client, bufnr)
					vim.api.nvim_buf_set_option(bufnr, "commentstring", "# %s")
				end,
			})
			vim.lsp.config("lua_ls", {
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
			vim.lsp.config("lspconfig", {
				-- NOTE: Uncomment to enable volar in file types other than vue.
				-- (Similar to Takeover Mode)
				-- IMPORTANT: Make sure ts_ls has a ts_ls.config.json and ts_ls.json file for your project!
				-- filetypes = { "vue", "javascript", "typescript", "javascriptreact", "typescriptreact", "json" },

				-- NOTE: Uncomment to restrict Volar to only Vue/Nuxt projects. This will enable Volar to work alongside other language servers (ts_ls).

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
			local mason_packages = vim.fn.stdpath("data") .. "/mason/packages"
			local volar_path = mason_packages .. "/vue-language-server/node_modules/@vue/language-server"

			vim.lsp.config("lspconfig", {
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
