return {
	{
		"nvim-telescope/telescope-ui-select.nvim",
	},
	{
		"nvim-telescope/telescope.nvim",
		tag = "0.1.5",
		dependencies = {
			"nvim-lua/plenary.nvim",
			{ "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
			"nvim-tree/nvim-web-devicons",
			"folke/todo-comments.nvim",
		},
		config = function()
			require("telescope").setup({
				extensions = {
					["ui-select"] = {
						require("telescope.themes").get_dropdown({}),
					},
				},
			})
			local builtin = require("telescope.builtin")
			local keymap = vim.keymap

			keymap.set("n", "<leader>tf", builtin.find_files, { desc = "Fuzzy by filename" })
			keymap.set("n", "<leader>to", builtin.oldfiles, { desc = "Fuzzy search recent files" })
			keymap.set("n", "<leader>tr", builtin.resume, { desc = "Go back to last search" })
			keymap.set("n", "<leader>ts", builtin.live_grep, { desc = "Find string in cwd" })
			keymap.set({ "n" }, "<leader>tc", builtin.commands, { desc = "Find string under cursor in cwd" })
			-- keymap.set("n", "<leader>tt", builtin.T, { desc = "Find todos" })
			keymap.set("n", "<leader>th", builtin.help_tags, { desc = "Help Search" })
			keymap.set("n", "<leader>tj", builtin.jumplist, { desc = "Search though jumplist history" })
			keymap.set("n", "<leader>tk", builtin.keymaps, { desc = "Search though keymaps" })
			keymap.set(
				"n",
				"<leader>tb",
				builtin.current_buffer_fuzzy_find,
				{ desc = "Search though jumplist history" }
			)
			require("telescope").load_extension("ui-select")
		end,
	},
}
