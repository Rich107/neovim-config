return {
	{
		"nvim-treesitter/nvim-treesitter",
		build = ":TSUpdate",
		event = { "BufReadPost", "BufNewFile" },
		config = function()
			require("nvim-treesitter.configs").setup({
				auto_install = true,
				highlight = { enable = true },
				indent = { enable = true },
				ensure_installed = { "vue", "scss", "css", "html", "javascript", "python" },
				-- Configuring the textobjects module
				textobjects = {
					select = {
						enable = true,
						lookahead = true,
						keymaps = {
							-- Function selection (inner and outer)
							["af"] = "@function.outer",
							["if"] = "@function.inner",
							-- Class selection (inner and outer)
							["ac"] = "@class.outer",
							["ic"] = "@class.inner",
							["ai"] = "@indent.outer", -- Select around the indentation level
							["ii"] = "@indent.inner", -- Select inside the indentation level
						},
					},
					move = {
						enable = true,
						set_jumps = true,
						goto_next_start = {
							["]f"] = "@function.outer",
						},
						goto_next_end = {
							["]F"] = "@function.outer",
						},
						goto_previous_start = {
							["[f"] = "@function.outer",
						},
						goto_previous_end = {
							["[F"] = "@function.outer",
						},
					},
					-- swap = {
					--     enable = true,
					--     swap_next = {
					--         ["<leader>a"] = "@parameter.inner",
					--     },
					--     swap_previous = {
					--         ["<leader>A"] = "@parameter.inner",
					--     },
					-- },
				},
			})
		end,
	},
	{
		"nvim-treesitter/nvim-treesitter-textobjects",
		after = "nvim-treesitter",
	},
}
