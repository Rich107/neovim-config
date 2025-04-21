-- return {
-- 	"jackMort/ChatGPT.nvim",
-- 	dependencies = {
-- 		"MunifTanjim/nui.nvim",
-- 		"nvim-lua/plenary.nvim",
-- 		"nvim-telescope/telescope.nvim",
-- 	},
-- 	config = function()
-- 		require("chatgpt").setup()
-- 	end,
-- }
--
--

-- return {
-- 	"https://github.com/github/copilot.vim.git",
-- }
--
--
return {
	{
		"CopilotC-Nvim/CopilotChat.nvim",
		dependencies = {
			{
				"github/copilot.vim",
				config = function()
					vim.g.copilot_no_tab_map = false
				end,
			},
			{ "nvim-lua/plenary.nvim", branch = "master" },
		},
		build = "make tiktoken",
		opts = {
			mappings = {
				reset = {
					normal = "<Leader>rrr",
					insert = false,
				},
				complete = {
					insert = false,
				},
			},
		},
	},
}
