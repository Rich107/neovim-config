local M = {}

local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")

-- Get branches sorted by most recent commit
local function get_branches(include_remote)
	local cmd
	if include_remote then
		-- All branches (local + remote), sorted by committerdate
		cmd = "git branch -a --sort=-committerdate --format='%(refname:short)'"
	else
		-- Local branches only, sorted by committerdate
		cmd = "git branch --sort=-committerdate --format='%(refname:short)'"
	end

	local result = vim.fn.systemlist(cmd)
	if vim.v.shell_error ~= 0 then
		return {}
	end

	-- Filter out HEAD pointer and clean up
	local branches = {}
	for _, branch in ipairs(result) do
		-- Skip HEAD pointer entries
		if not branch:match("HEAD") and branch ~= "" then
			table.insert(branches, branch)
		end
	end

	return branches
end

local function create_picker(include_remote)
	local mode = include_remote and "All" or "Local"
	local toggle_hint = include_remote and "<C-a>: local only" or "<C-a>: include remote"
	local prompt_title = string.format("Git Branches [%s] (<CR>: checkout | <C-x>: delete | %s)", mode, toggle_hint)

	local branches = get_branches(include_remote)

	pickers
		.new({}, {
			prompt_title = prompt_title,
			previewer = false,
			finder = finders.new_table({
				results = branches,
			}),
			sorter = conf.generic_sorter({}),
			attach_mappings = function(prompt_bufnr, map)
				-- Checkout branch on enter
				actions.select_default:replace(function()
					local selection = action_state.get_selected_entry()
					if not selection then
						return
					end
					actions.close(prompt_bufnr)

					local branch_name = selection[1]
					-- Remove "origin/" or "remotes/origin/" prefix for remote branches
					local local_branch = branch_name:gsub("^remotes/", ""):gsub("^origin/", "")

					vim.cmd("Git checkout " .. vim.fn.shellescape(local_branch))
				end)

				-- Delete branch with Ctrl+x
				local function delete_branch()
					local selection = action_state.get_selected_entry()
					if not selection then
						vim.notify("No branch selected", vim.log.levels.WARN)
						return
					end

					local branch_name = selection[1]

					-- Check if this is a remote branch
					if branch_name:match("^origin/") or branch_name:match("^remotes/") then
						vim.notify("Cannot delete remote branch: " .. branch_name, vim.log.levels.ERROR)
						return
					end

					-- Get current branch
					local current_branch = vim.fn.systemlist("git branch --show-current")[1]

					if branch_name == current_branch then
						vim.notify("Cannot delete current branch: " .. branch_name, vim.log.levels.ERROR)
						return
					end

					local result = vim.fn.system("git branch -D " .. vim.fn.shellescape(branch_name))

					if vim.v.shell_error == 0 then
						print("Deleted branch: " .. branch_name)
						actions.close(prompt_bufnr)
						-- Reopen picker to refresh
						vim.schedule(function()
							create_picker(include_remote)
						end)
					else
						print("Failed to delete branch: " .. result)
					end
				end

				-- Toggle between local and all branches with Ctrl+a
				local function toggle_remote()
					local current_line = action_state.get_current_line()
					actions.close(prompt_bufnr)
					vim.schedule(function()
						create_picker(not include_remote)
						-- Restore the search text if there was any
						if current_line and current_line ~= "" then
							vim.schedule(function()
								vim.api.nvim_feedkeys(current_line, "n", false)
							end)
						end
					end)
				end

				map("i", "<C-x>", delete_branch)
				map("n", "<C-x>", delete_branch)
				map("i", "<C-a>", toggle_remote)
				map("n", "<C-a>", toggle_remote)

				return true
			end,
		})
		:find()
end

function M.pick_branch()
	-- Start with local branches only
	create_picker(false)
end

return M
