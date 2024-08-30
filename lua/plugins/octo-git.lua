return {
	"pwntester/octo.nvim",
	dependencies = {
		"nvim-lua/plenary.nvim", -- Required by octo.nvim
		"nvim-telescope/telescope.nvim", -- Or use 'ibhagwan/fzf-lua'
		"nvim-tree/nvim-web-devicons", -- Required for icons
	},
	config = function()
		-- Check if GitHub CLI is installed
		if vim.fn.executable("gh") == 1 then
			require("octo").setup()
		else
			vim.notify("GitHub CLI (gh) not found. Please install it.", vim.log.levels.ERROR)
		end
	end,
}
