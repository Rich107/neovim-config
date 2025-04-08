return {
	{
		"epwalsh/obsidian.nvim",
		version = "*",
		lazy = true,
		ft = "markdown",
		dependencies = {
			"nvim-lua/plenary.nvim",

			{
				"nvim-treesitter/nvim-treesitter",
				build = ":TSUpdate",
				config = function()
					require("nvim-treesitter.configs").setup({
						ensure_installed = { "markdown", "markdown_inline" },
						highlight = {
							enable = true,
							additional_vim_regex_highlighting = false,
						},
					})
				end,
			},

			{
				"MeanderingProgrammer/render-markdown.nvim",
				config = function()
					require("render-markdown").setup({
						headings = { "▍", "▌", "▋", "▊", "▉", "█" },
						bullets = { "•", "◦", "▪", "▫" },
						checkboxes = {
							["[ ]"] = "󰄱", -- unchecked
							["[x]"] = "", -- checked
							["[-]"] = "󰦖", -- partially checked
						},
						quote = "┃", -- for normal blockquotes
						callouts = {
							["note"] = { icon = "📝", color = "Hint" },
							["abstract"] = { icon = "📄", color = "String" },
							["info"] = { icon = "ℹ️", color = "Special" },
							["tip"] = { icon = "💡", color = "Number" },
							["success"] = { icon = "✔️", color = "DiffAdd" },
							["question"] = { icon = "❓", color = "DiagnosticInfo" },
							["warning"] = { icon = "⚠️", color = "WarningMsg" },
							["failure"] = { icon = "❌", color = "Error" },
							["danger"] = { icon = "🔥", color = "ErrorMsg" },
							["bug"] = { icon = "🐛", color = "DiagnosticError" },
							["example"] = { icon = "📌", color = "Identifier" },
							["quote"] = { icon = "❝", color = "Comment" },
						},
						conceal = true,
					})
				end,
			},
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
