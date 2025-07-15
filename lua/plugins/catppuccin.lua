return {
	{
		"catppuccin/nvim",
		lazy = false,
		name = "catppuccin",
		priority = 1000,
		config = function()
			require("catppuccin").setup({
				transparent = true,
				transparent_background = true,
				styles = {
					sidebars = "transparent",
					floats = "transparent",
				},
			})
			-- Set up the colorscheme
			vim.cmd.colorscheme("catppuccin-mocha")
			-- Set vertical split color (use WinSeparator in newer Neovim, VertSplit for backward compatibility)
			vim.api.nvim_set_hl(0, "WinSeparator", { fg = "#ffffff", bg = "None", ctermfg = "white", ctermbg = "None" })
			-- Set horizontal split (status line) color
			vim.api.nvim_set_hl(
				0,
				"StatusLine",
				{ fg = "#ffffff", bg = "#000000", ctermfg = "white", ctermbg = "black" }
			)
			vim.api.nvim_set_hl(
				0,
				"StatusLineNC",
				{ fg = "#ffffff", bg = "#000000", ctermfg = "white", ctermbg = "black" }
			)
			-- Apply the highlight group to window separators
			-- vim.o.winhighlight = "VertSplit:WinSeparator"
			vim.o.winhighlight = "WinSeparator:WinSeparator"
			vim.o.laststatus = 3
		end,
	},
}
