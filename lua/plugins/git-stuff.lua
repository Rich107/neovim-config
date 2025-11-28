return {
	{ "tpope/vim-fugitive" },
	{
		"sindrets/diffview.nvim",
		cmd = { "DiffviewOpen", "DiffviewClose" },
		dependencies = { "nvim-lua/plenary.nvim" },
	},
	{
		"kdheepak/lazygit.nvim",
		cmd = {
			"LazyGit",
			"LazyGitConfig",
			"LazyGitCurrentFile",
			"LazyGitFilter",
			"LazyGitFilterCurrentFile",
		},
		-- optional for floating window border decoration
		dependencies = {
			"nvim-lua/plenary.nvim",
		},
		-- setting the keybinding for LazyGit with 'keys' is recommended in
		-- order to load the plugin when the command is run for the first time
		keys = {
			{ "<leader>gg", "<cmd>LazyGit<cr>", desc = "Open lazy git" },
		},
		config = function()
			vim.g.lazygit_floating_window_winblend = 0 -- transparency of floating window
			vim.g.lazygit_floating_window_scaling_factor = 1.0 -- scaling factor for floating window
			vim.g.lazygit_floating_window_border_chars = {'─','│','─','│','╭','╮','╯','╰'} -- customize lazygit popup window border characters
			vim.g.lazygit_floating_window_use_plenary = 0 -- use plenary.nvim to manage floating window if available
			vim.g.lazygit_use_neovim_remote = 1 -- fallback to 0 if neovim-remote is not installed
		end,
	},
	{
		"lewis6991/gitsigns.nvim",
		config = function()
			require("gitsigns").setup({
				-- Disable for large files
				max_file_length = 4000, -- default was 40000, changing to 4000
				
				-- Performance optimizations
				watch_gitdir = {
					interval = 1000, -- default 1000
					followfiles = true,
				},
				
				-- Set larger debounce time for better performance
				update_debounce = 200, -- default 100
				
				-- Don't use current line blame by default
				current_line_blame = false,
				
				-- Disable if file is larger than threshold
				attach_to_untracked = false,
				
				-- Custom attach handler
				_loading_gitsigns_custom_attach = function(bufnr)
					-- Check line count
					local line_count = vim.api.nvim_buf_line_count(bufnr)
					if line_count > 4000 then
						return false -- Don't attach
					end
					return true -- Attach as normal
				end
			})
			
			-- Add keymaps
			vim.keymap.set("n", "<leader>gsp", ":Gitsigns preview_hunk<CR>", {})
			vim.keymap.set("n", "<leader>gst", ":Gitsigns toggle_current_line_blame<CR>", {})
			vim.keymap.set("n", "<leader>gsb", ":Gitsigns blame<CR>", {})
			
			-- Add a command to completely disable gitsigns for the current buffer
			vim.api.nvim_create_user_command("DisableGitSigns", function()
				vim.cmd("Gitsigns detach")
				vim.notify("GitSigns disabled for this buffer")
			end, {})
		end,
	},
}
