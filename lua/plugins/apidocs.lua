return {
	"emmanueltouzery/apidocs.nvim",
	dependencies = {
		"nvim-treesitter/nvim-treesitter",
		"nvim-telescope/telescope.nvim",
	},
	cmd = { "ApidocsSearch", "ApidocsInstall", "ApidocsOpen", "ApidocsSelect", "ApidocsUninstall" },
	config = function()
		require("apidocs").setup()
	end,
	keys = {
		{ "<leader>tdd", "<cmd>ApidocsOpen<cr>", desc = "Search API Docs (DevDocs)" },
		{ "<leader>tds", "<cmd>ApidocsSearch<cr>", desc = "Search in API Docs (DevDocs)" },
	},
}
