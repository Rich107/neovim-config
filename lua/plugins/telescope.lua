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
				defaults = {
					file_ignore_patterns = {
						"node_modules",
						"lib",
					},
					-- Customizing path display to show only the filename and first two parent folders
					path_display = function(opts, path)
						local tail = require("telescope.utils").path_tail(path)
						local dirs = vim.split(vim.fn.fnamemodify(path, ":.:h"), "/")
						local parent_dirs = ""
						if #dirs > 1 then
							parent_dirs = table.concat(dirs, "/", math.max(#dirs - 1, #dirs - 2))
						else
							parent_dirs = dirs[1] or ""
						end
						return parent_dirs .. "/" .. tail
					end,
				},
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
			keymap.set("n", "<leader>t.", builtin.oldfiles, { desc = "Fuzzy search recent files" })
			keymap.set("n", "<leader>tr", builtin.resume, { desc = "Go back to last search" })
			keymap.set("n", "<leader>ts", builtin.live_grep, { desc = "Find string in cwd" })
			keymap.set({ "n", "v" }, "<leader>tv", builtin.grep_string, { desc = "Find selected string in cwd" })
			keymap.set("n", "<leader>tc", builtin.commands, { desc = "Find string under cursor in cwd" })
			keymap.set("n", "<leader>tt", "<cmd>TodoTelescope<cr>", { desc = "Find todos" })
			keymap.set("n", "<leader>th", builtin.help_tags, { desc = "Help Search" })
			keymap.set("n", "<leader>tj", builtin.jumplist, { desc = "Search though jumplist history" })
			keymap.set("n", "<leader>tk", builtin.keymaps, { desc = "Search though keymaps" })
			keymap.set("n", "<leader>td", function()
				builtin.diagnostics({ bufnr = 0 })
			end, { desc = "Search diagnostics in current buffer" })

			-- keymap.set(
			-- 	"n",
			-- 	"<leader>tb",
			-- 	builtin.current_buffer_fuzzy_find,
			-- 	{ desc = "Search though jumplist history" }
			-- )

			-- Slightly advanced example of overriding default behavior and theme
			vim.keymap.set("n", "<leader>/", function()
				-- You can pass additional configuration to Telescope to change the theme, layout, etc.
				builtin.current_buffer_fuzzy_find(require("telescope.themes").get_dropdown({
					winblend = 10,
					previewer = false,
				}))
			end, { desc = "[/] Fuzzily search in current buffer" })

			-- It's also possible to pass additional configuration options.
			--  See `:help telescope.builtin.live_grep()` for information about particular keys
			vim.keymap.set("n", "<leader>t/", function()
				builtin.live_grep({
					grep_open_files = true,
					prompt_title = "Live Grep in Open Files",
				})
			end, { desc = "[S]earch [/] in Open Files" })

			require("telescope").load_extension("ui-select")
			require("telescope").load_extension("fzf")
		end,
	},
}
