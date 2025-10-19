return {
	"amitds1997/remote-nvim.nvim",
	version = "*", -- Pin to GitHub releases
	dependencies = {
		"nvim-lua/plenary.nvim", -- For standard functions
		"MunifTanjim/nui.nvim", -- To build the plugin UI
		"nvim-telescope/telescope.nvim", -- For picking b/w different remote methods
	},
	config = function()
		require("remote-nvim").setup({
			-- Configuration goes here
			client_callback = function(port, _)
				-- This ensures proper clipboard handling
				vim.schedule(function()
					-- Force OSC 52 clipboard for remote connections
					vim.g.clipboard = {
						name = "OSC 52",
						copy = {
							["+"] = require("vim.ui.clipboard.osc52").copy("+"),
							["*"] = require("vim.ui.clipboard.osc52").copy("*"),
						},
						paste = {
							["+"] = require("vim.ui.clipboard.osc52").paste("+"),
							["*"] = require("vim.ui.clipboard.osc52").paste("*"),
						},
					}
				end)
			end,
		})
	end,
}