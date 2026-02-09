return {
	"uga-rosa/ccc.nvim",
	event = "VeryLazy",
	keys = {
		{ "<leader>cp", "<cmd>CccPick<cr>", desc = "Color picker" },
	},
	opts = {
		highlighter = {
			auto_enable = true,
			lsp = true,
		},
	},
}
