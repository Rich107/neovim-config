return {
	"git-auto-fetch",
	name = "git-auto-fetch",
	dir = vim.fn.stdpath("config"),
	event = "VeryLazy",
	config = function()
		local timer = nil
		local fetch_in_progress = false

		-- Function to check if current directory is a git repo
		local function is_git_repo()
			local handle = io.popen("git rev-parse --is-inside-work-tree 2>/dev/null")
			if handle then
				local result = handle:read("*a")
				handle:close()
				return result:match("true") ~= nil
			end
			return false
		end

		-- Function to clean up reference conflicts
		local function cleanup_ref_conflicts()
			if not is_git_repo() then
				return false
			end

			local cleaned = false
			
			-- Try to clean up packed refs first
			vim.fn.system("git pack-refs --all --prune")
			
			-- Remove any stale remote tracking branches
			local stale_branches = vim.fn.system("git remote prune origin --dry-run 2>&1")
			if stale_branches and stale_branches ~= "" then
				vim.fn.system("git remote prune origin")
				cleaned = true
			end
			
			-- Clean up any refs that might be causing conflicts
			vim.fn.system("git gc --prune=now")
			
			return cleaned
		end

		-- Function to perform git fetch with aggressive prune
		local function git_fetch_and_prune(force_cleanup)
			-- Skip if a fetch is already in progress
			if fetch_in_progress then
				return
			end

			-- Check if we're in a git repository
			if not is_git_repo() then
				return
			end

			fetch_in_progress = true
			
			-- Clean up references if forced or if we detect potential conflicts
			if force_cleanup then
				cleanup_ref_conflicts()
			end

			-- Run git fetch with aggressive pruning options
			-- --prune removes remote tracking branches that no longer exist on remote
			-- --prune-tags removes local tags that don't exist on remote
			local fetch_cmd = "git fetch --all --prune --prune-tags"
			
			vim.fn.jobstart(fetch_cmd, {
				on_exit = function(_, exit_code)
					fetch_in_progress = false
					if exit_code == 0 then
						-- Get the remote tracking branch status
						local handle = io.popen("git status -sb 2>/dev/null | head -1")
						if handle then
							local status = handle:read("*a")
							handle:close()

							-- Parse the status to check if we're behind
							local behind = status:match("behind (%d+)")
							local ahead = status:match("ahead (%d+)")
							
							local message = "Git fetch completed successfully"
							if behind then
								message = message .. " (behind by " .. behind .. " commits)"
								vim.notify(message, vim.log.levels.WARN)
							elseif ahead then
								message = message .. " (ahead by " .. ahead .. " commits)"
								vim.notify(message, vim.log.levels.INFO)
							else
								-- Only show success message if explicitly enabled
								if vim.g.git_auto_fetch_notify_success then
									vim.notify(message, vim.log.levels.INFO)
								end
							end
						end
					elseif exit_code ~= 0 then
						-- Only notify on actual errors, not network timeouts
						if vim.g.git_auto_fetch_notify_errors ~= false then
							vim.notify("Git fetch failed (exit code: " .. exit_code .. ")", vim.log.levels.ERROR)
						end
					end
				end,
				on_stderr = function(_, data)
					local has_ref_conflict = false
					for _, line in ipairs(data) do
						if line ~= "" then
							-- Check for reference directory conflicts
							if line:match("fatal: Reference directory conflict") or 
							   line:match("fatal: Couldn't find remote ref") or
							   line:match("fatal: bad object") then
								has_ref_conflict = true
							end
							
							-- Log stderr output for debugging
							if vim.g.git_auto_fetch_debug then
								vim.notify("Git fetch stderr: " .. line, vim.log.levels.DEBUG)
							end
						end
					end
					
					-- If we detected a reference conflict, try to fix it
					if has_ref_conflict and not force_cleanup then
						fetch_in_progress = false
						vim.notify("Reference conflict detected, attempting cleanup...", vim.log.levels.WARN)
						
						-- Schedule a cleanup and retry
						vim.defer_fn(function()
							cleanup_ref_conflicts()
							-- Retry fetch with force_cleanup flag to prevent infinite loop
							git_fetch_and_prune(true)
						end, 100)
					end
				end,
			})
		end

		-- Function to start the auto-fetch timer
		local function start_auto_fetch()
			if timer then
				timer:stop()
				timer:close()
			end

			-- Initial fetch when starting
			git_fetch_and_prune()

			-- Set up timer for every 2 minutes (120000 ms)
			timer = vim.loop.new_timer()
			timer:start(
				120000, -- initial delay (2 minutes)
				120000, -- repeat interval (2 minutes)
				vim.schedule_wrap(function()
					git_fetch_and_prune()
				end)
			)
		end

		-- Function to stop the auto-fetch timer
		local function stop_auto_fetch()
			if timer then
				timer:stop()
				timer:close()
				timer = nil
				vim.notify("Git auto-fetch stopped", vim.log.levels.INFO)
			end
		end

		-- Function to manually fix reference conflicts
		local function fix_ref_conflicts()
			if not is_git_repo() then
				vim.notify("Not in a git repository", vim.log.levels.ERROR)
				return
			end
			
			vim.notify("Cleaning up git references...", vim.log.levels.INFO)
			
			-- More aggressive cleanup for manual intervention
			local commands = {
				"git remote prune origin",
				"git gc --prune=now",
				"git pack-refs --all --prune",
				"git fsck --full",
				"git reflog expire --expire=now --all",
				"git gc --aggressive --prune=now"
			}
			
			for _, cmd in ipairs(commands) do
				local result = vim.fn.system(cmd .. " 2>&1")
				if vim.g.git_auto_fetch_debug then
					vim.notify("Running: " .. cmd .. "\nResult: " .. (result or ""), vim.log.levels.DEBUG)
				end
			end
			
			vim.notify("Git reference cleanup completed. Try fetching again.", vim.log.levels.INFO)
			
			-- Try a fetch after cleanup
			vim.defer_fn(function()
				git_fetch_and_prune(true)
			end, 500)
		end

		-- Create user commands
		vim.api.nvim_create_user_command("GitAutoFetchStart", start_auto_fetch, {
			desc = "Start automatic git fetch every 2 minutes",
		})

		vim.api.nvim_create_user_command("GitAutoFetchStop", stop_auto_fetch, {
			desc = "Stop automatic git fetch",
		})

		vim.api.nvim_create_user_command("GitFetchNow", function()
			git_fetch_and_prune(false)
		end, {
			desc = "Manually trigger git fetch with prune",
		})
		
		vim.api.nvim_create_user_command("GitFixRefs", fix_ref_conflicts, {
			desc = "Fix git reference conflicts and clean up repository",
		})

		-- Set up keymaps
		vim.keymap.set("n", "<leader>gfa", start_auto_fetch, { desc = "Start git auto-fetch" })
		vim.keymap.set("n", "<leader>gfs", stop_auto_fetch, { desc = "Stop git auto-fetch" })
		vim.keymap.set("n", "<leader>gff", function() git_fetch_and_prune(false) end, { desc = "Git fetch now" })
		vim.keymap.set("n", "<leader>gfr", fix_ref_conflicts, { desc = "Fix git reference conflicts" })

		-- Configuration variables (can be set in init.lua or vim-options.lua)
		-- vim.g.git_auto_fetch_notify_success = false  -- Don't show success notifications
		-- vim.g.git_auto_fetch_notify_errors = true    -- Show error notifications
		-- vim.g.git_auto_fetch_debug = false           -- Show debug information
		-- vim.g.git_auto_fetch_autostart = true        -- Automatically start on load

		-- Auto-start if configured (default is true)
		if vim.g.git_auto_fetch_autostart ~= false then
			start_auto_fetch()
		end

		-- Clean up timer on Neovim exit
		vim.api.nvim_create_autocmd("VimLeavePre", {
			callback = function()
				stop_auto_fetch()
			end,
		})
	end,
}