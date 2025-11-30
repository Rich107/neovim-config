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
			
			-- Create git branch with spell checking
			local function create_git_branch()
				-- Create a floating window
				local buf = vim.api.nvim_create_buf(false, true)
				local width = 60
				local height = 3
				
			local win = vim.api.nvim_open_win(buf, true, {
				relative = "editor",
				width = width,
				height = height,
				col = (vim.o.columns - width) / 2,
				row = (vim.o.lines - height) / 2,
				style = "minimal",
				border = "rounded",
				title = " Create Git Branch ",
				title_pos = "center",
			})
			
			-- Enable spell checking in the window
			vim.api.nvim_win_set_option(win, "spell", true)
			vim.api.nvim_win_set_option(win, "spelllang", "en")
				
				-- Set buffer options
				vim.api.nvim_set_option_value("buftype", "prompt", { buf = buf })
				vim.fn.prompt_setprompt(buf, "Branch: ")
				
			-- Function to create the branch
			local function do_create_branch()
				local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
				local input = lines[1]:gsub("^Branch: ", "")
				
				-- Trim whitespace from edges
				input = input:gsub("^%s*(.-)%s*$", "%1")
				
				if input == "" then
					vim.api.nvim_win_close(win, true)
					vim.api.nvim_buf_delete(buf, { force = true })
					vim.notify("Branch name cannot be empty", vim.log.levels.WARN)
					return
				end
				
				-- Replace spaces with hyphens
				local branch_name = input:gsub("%s+", "-")
				
				-- Close the window and delete the buffer
				vim.api.nvim_win_close(win, true)
				vim.api.nvim_buf_delete(buf, { force = true })
				
				-- Create the branch
				local result = vim.fn.systemlist("git checkout -b " .. vim.fn.shellescape(branch_name))
				
				if vim.v.shell_error == 0 then
					vim.notify("Created and switched to branch: " .. branch_name, vim.log.levels.INFO)
				else
					vim.notify("Failed to create branch: " .. table.concat(result, "\n"), vim.log.levels.ERROR)
				end
			end
				
				-- Set up keymaps for the prompt buffer
				vim.keymap.set("i", "<CR>", do_create_branch, { buffer = buf })
				vim.keymap.set("i", "<Esc>", function()
					vim.api.nvim_win_close(win, true)
					vim.api.nvim_buf_delete(buf, { force = true })
				end, { buffer = buf })
				
				-- Start in insert mode
				vim.cmd("startinsert")
			end
			
		-- Create the command and keymap
		vim.api.nvim_create_user_command("CreateGitBranch", create_git_branch, {})
		vim.keymap.set("n", "<leader>cgb", create_git_branch, { desc = "Create git branch (spell-checked)" })
		
		-- Git push and pull commands
		vim.keymap.set("n", "<leader>gp", function()
			print("Pushing to remote...")
			local result = vim.fn.systemlist("git push")
			if vim.v.shell_error == 0 then
				print("Push successful!")
			else
				print("Push failed: " .. table.concat(result, "\n"))
			end
		end, { desc = "Git push" })
		
		vim.keymap.set("n", "<leader>gl", function()
			print("Pulling from remote...")
			local result = vim.fn.systemlist("git pull")
			if vim.v.shell_error == 0 then
				print("Pull successful!")
			else
				print("Pull failed: " .. table.concat(result, "\n"))
			end
		end, { desc = "Git pull" })
		
		-- Auto command to open commit messages in floating window
		vim.api.nvim_create_autocmd("FileType", {
			pattern = "gitcommit",
			callback = function()
				local buf = vim.api.nvim_get_current_buf()
				local current_win = vim.api.nvim_get_current_win()
				
				-- Only convert to floating if it's not already floating
				local win_config = vim.api.nvim_win_get_config(current_win)
				if win_config.relative == "" then
					-- Calculate window size (80% of editor)
					local width = math.floor(vim.o.columns * 0.8)
					local height = math.floor(vim.o.lines * 0.8)
					local row = math.floor((vim.o.lines - height) / 2)
					local col = math.floor((vim.o.columns - width) / 2)
					
					-- Close current window
					vim.api.nvim_win_close(current_win, false)
					
					-- Open as floating window
					vim.api.nvim_open_win(buf, true, {
						relative = "editor",
						width = width,
						height = height,
						row = row,
						col = col,
						style = "minimal",
						border = "rounded",
						title = " Git Commit ",
						title_pos = "center",
					})
				end
				
				-- Disable <Esc> from closing the window
				vim.keymap.set("n", "<Esc>", "<Nop>", { buffer = buf, silent = true })
			end,
		})
		
		vim.keymap.set("n", "<leader>gc", "<cmd>Git commit<CR>", { desc = "Git commit", silent = true })
		end,
	},
}
