return {
	"Wansmer/treesj",
	-- keys = { '<space>m', '<space>j', '<space>s' },
	dependencies = { "nvim-treesitter/nvim-treesitter" }, -- if you install parsers with `nvim-treesitter`
	config = function()
		require("treesj").setup({
			use_default_keymaps = false,
			max_join_length = 240,
		})
		-- Set custom keymap for toggling
		vim.keymap.set("n", "<leader>jj", "<Cmd>TSJToggle<CR>", { desc = "Toggle Treesitter Join" })
	end,
}
