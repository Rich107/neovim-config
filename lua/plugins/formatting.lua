return {
	"stevearc/conform.nvim",
	event = { "BufReadPre", "BufNewFile" },
	config = function()
		local conform = require("conform")

		conform.setup({
			formatters_by_ft = {
				javascript = { "biome" },
				typescript = { "biome" },
				javascriptreact = { "biome" },
				typescriptreact = { "biome" },
				svelte = { "biome" },
				css = { "biome" },
				html = { "biome" },
				django = { "djhmtl" },
				json = { "biome" },
				yaml = { "biome" },
				markdown = { "biome" },
				graphql = { "biome" },
				liquid = { "biome" },
				lua = { "stylua" },
				python = { "ruff" },
			},
			format_on_save = {
				lsp_fallback = false,
				async = false,
				timeout_ms = 1000,
			},
		})
		-- Not going with this as it moved the curosr on run:
		-- vim.api.nvim_create_autocmd("BufWritePre", {
		-- 	pattern = "*.json",
		-- 	callback = function()
		-- 		vim.cmd("%!prettier --stdin-filepath %")
		-- 	end,
		-- })

		-- Map <leader>ff to format JSON with Prettier
		-- vim.keymap.set("n", "<leader>ff", function()
		-- local filetype = vim.bo.filetype
		-- if filetype == "json" then
		-- 	vim.cmd("%!prettier --stdin-filepath %")
		-- else
		-- 	conform.format({
		-- 		lsp_fallback = true,
		-- 		async = false,
		-- 		timeout_ms = 1000,
		-- 	})
		-- end
		-- end, { desc = "Format JSON with Prettier or use Conform for other filetypes" })

		vim.keymap.set({ "n", "v" }, "<leader>mp", function()
			conform.format({
				lsp_fallback = true,
				async = false,
				timeout_ms = 1000,
			})
		end, { desc = "Format file or range (in visual mode)" })
	end,
}
