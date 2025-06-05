return {
	{
		"epwalsh/obsidian.nvim",
		version = "*",
		ft = "markdown",
		dependencies = {
			"nvim-lua/plenary.nvim",

			-- Treesitter config
			-- {
			-- 	"nvim-treesitter/nvim-treesitter",
			-- 	build = ":TSUpdate",
			-- 	config = function()
			-- 		require("nvim-treesitter.configs").setup({
			-- 			ensure_installed = { "markdown", "markdown_inline" },
			-- 			highlight = {
			-- 				enable = true,
			-- 				additional_vim_regex_highlighting = false,
			-- 			},
			-- 		})
			-- 	end,
			-- },

			-- Markdown prettifier with callouts
			-- Its working better without this just without the cool call outs.
			-- Basic bullets were not working with this on and check boxes etc without it checks are working better
			-- {
			-- 	"MeanderingProgrammer/render-markdown.nvim",
			-- 	config = function()
			-- 		require("render-markdown").setup({
			-- 			conceal = true,
			-- 			callouts = {
			-- 				["note"] = { icon = "📝", color = "Normal" },
			-- 				["tip"] = { icon = "💡", color = "Special" },
			-- 				["info"] = { icon = "ℹ️", color = "Special" },
			-- 				["success"] = { icon = "✔️", color = "DiffAdd" },
			-- 				["question"] = { icon = "❓", color = "DiagnosticInfo" },
			-- 				["warning"] = { icon = "⚠️", color = "WarningMsg" },
			-- 				["failure"] = { icon = "❌", color = "Error" },
			-- 				["danger"] = { icon = "🔥", color = "ErrorMsg" },
			-- 				["bug"] = { icon = "🐛", color = "DiagnosticError" },
			-- 				["example"] = { icon = "📌", color = "Identifier" },
			-- 				["quote"] = { icon = "❝", color = "Comment" },
			-- 			},
			-- 			bullets = { "•", "◦", "▪", "▫" },
			-- 			checkboxes = {
			-- 				["[ ]"] = "󰄱",
			-- 				["[x]"] = "",
			-- 				["[-]"] = "󰦖",
			-- 			},
			-- 			quote = "┃",
			-- 			headings = { "▍", "▌", "▋", "▊", "▉", "█" },
			-- 		})
			--
			-- 		vim.opt.conceallevel = 3
			-- 		vim.opt.concealcursor = "nciv"
			-- 	end,
			-- },
		},
		opts = {
			workspaces = {
				{
					name = "Personal",
					path = "~/Documents/Obsidian Vaults/Personal",
				},
				{
					name = "work",
					path = "~/Documents/Obsidian Vaults/Legl",
				},
			},
		},
	},
}
