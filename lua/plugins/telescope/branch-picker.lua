local M = {}

function M.pick_branch()
	local builtin = require("telescope.builtin")
	
	builtin.git_branches({ 
		previewer = false,
		prompt_title = "Git Branches (<CR>: checkout | <C-x>: delete)",
		attach_mappings = function(prompt_bufnr, map)
			local actions = require("telescope.actions")
			local action_state = require("telescope.actions.state")
			
			-- Replace default action to checkout branch
			actions.select_default:replace(function()
				local selection = action_state.get_selected_entry()
				actions.close(prompt_bufnr)
				
				-- Extract branch name from the selection
				local branch_name = selection.value
				-- Remove "origin/" prefix if present for remote branches
				local local_branch = branch_name:gsub("^origin/", "")
				
				-- Check out the branch by name, not commit
				vim.cmd("Git checkout " .. vim.fn.shellescape(local_branch))
			end)
			
			-- Add Ctrl+x mapping to delete branch
			local function delete_branch()
				local selection = action_state.get_selected_entry()
				if not selection then
					vim.notify("No branch selected", vim.log.levels.WARN)
					return
				end
				
				local branch_name = selection.value
				
				-- Check if this is a remote branch
				if branch_name:match("^origin/") then
					vim.notify("Cannot delete remote branch: " .. branch_name, vim.log.levels.ERROR)
					return
				end
				
				-- Get current branch
				local current_branch = vim.fn.systemlist("git branch --show-current")[1]
				
				-- Check if trying to delete current branch
				if branch_name == current_branch then
					vim.notify("Cannot delete current branch: " .. branch_name, vim.log.levels.ERROR)
					return
				end
				
				-- Try to delete the branch (force delete) without closing picker
				local result = vim.fn.system("git branch -D " .. vim.fn.shellescape(branch_name))
				
				if vim.v.shell_error == 0 then
					print("Deleted branch: " .. branch_name)
					-- Close and reopen to refresh the list
					actions.close(prompt_bufnr)
				else
					print("Failed to delete branch: " .. result)
				end
			end
			
			-- Map Ctrl+x in both insert and normal mode
			map("i", "<C-x>", delete_branch)
			map("n", "<C-x>", delete_branch)
			
			return true
		end
	})
end

return M
