local M = {}

local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local entry_display = require("telescope.pickers.entry_display")

-- Cache the git user email
local git_user_email = nil
local function get_git_user_email()
	if git_user_email then
		return git_user_email
	end
	local result = vim.fn.systemlist("git config user.email")
	if vim.v.shell_error == 0 and result[1] then
		git_user_email = result[1]:lower()
	end
	return git_user_email
end

-- Get branches sorted by most recent commit with author and date
local function get_branches(include_remote, my_branches_only)
	local flag = include_remote and "-a" or ""
	-- Format: branch name | author name | author email | relative date
	local format = "%(refname:short)|%(authorname)|%(authoremail:trim)|%(committerdate:relative)"
	local cmd = string.format("git branch %s --sort=-committerdate --format='%s'", flag, format)

	local result = vim.fn.systemlist(cmd)
	if vim.v.shell_error ~= 0 then
		return {}
	end

	local user_email = my_branches_only and get_git_user_email() or nil

	local branches = {}
	for _, line in ipairs(result) do
		-- Skip HEAD pointer entries and empty lines
		if not line:match("HEAD") and line ~= "" then
			local branch, author, email, date = line:match("([^|]+)|([^|]*)|([^|]*)|([^|]*)")
			if branch then
				-- Filter by user email if my_branches_only is set
				local include = true
				if my_branches_only and user_email then
					include = email:lower() == user_email
				end

				if include then
					table.insert(branches, {
						name = branch,
						author = author or "",
						date = date or "",
					})
				end
			end
		end
	end

	return branches
end

local function create_picker(include_remote, my_branches_only)
	local mode = include_remote and "All" or "Local"
	if my_branches_only then
		mode = "Mine"
	end

	local hints = {}
	if not include_remote then
		table.insert(hints, "<C-a>: all")
	else
		table.insert(hints, "<C-a>: local")
	end
	if not my_branches_only then
		table.insert(hints, "<C-y>: mine")
	else
		table.insert(hints, "<C-y>: all")
	end

	local prompt_title = string.format(
		"Git Branches [%s] (<CR>: checkout | <C-x>: delete | %s)",
		mode,
		table.concat(hints, " | ")
	)

	local branches = get_branches(include_remote or my_branches_only, my_branches_only)

	-- Calculate max widths for nice alignment
	local max_branch_len = 30
	local max_author_len = 15
	for _, b in ipairs(branches) do
		max_branch_len = math.max(max_branch_len, #b.name)
		max_author_len = math.max(max_author_len, #b.author)
	end
	-- Cap the widths to keep things reasonable
	max_branch_len = math.min(max_branch_len, 50)
	max_author_len = math.min(max_author_len, 20)

	local displayer = entry_display.create({
		separator = " ",
		items = {
			{ width = max_branch_len },
			{ width = max_author_len },
			{ remaining = true },
		},
	})

	local make_display = function(entry)
		return displayer({
			{ entry.value.name, "TelescopeResultsIdentifier" },
			{ entry.value.author, "TelescopeResultsComment" },
			{ entry.value.date, "TelescopeResultsNumber" },
		})
	end

	pickers
		.new({}, {
			prompt_title = prompt_title,
			previewer = false,
			finder = finders.new_table({
				results = branches,
				entry_maker = function(branch)
					return {
						value = branch,
						display = make_display,
						ordinal = branch.name .. " " .. branch.author,
					}
				end,
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

					local branch_name = selection.value.name
					-- Remove "origin/" or "remotes/origin/" prefix for remote branches
					local local_branch = branch_name:gsub("^remotes/", ""):gsub("^origin/", "")

					vim.cmd("Git checkout " .. local_branch)
				end)

				-- Delete branch with Ctrl+x
				local function delete_branch()
					local selection = action_state.get_selected_entry()
					if not selection then
						vim.notify("No branch selected", vim.log.levels.WARN)
						return
					end

					local branch_name = selection.value.name

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
							create_picker(include_remote, my_branches_only)
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
						create_picker(not include_remote, false)
						if current_line and current_line ~= "" then
							vim.schedule(function()
								vim.api.nvim_feedkeys(current_line, "n", false)
							end)
						end
					end)
				end

				-- Toggle my branches filter with Ctrl+m
				local function toggle_my_branches()
					local current_line = action_state.get_current_line()
					actions.close(prompt_bufnr)
					vim.schedule(function()
						create_picker(false, not my_branches_only)
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
			map("i", "<C-y>", toggle_my_branches)
			map("n", "<C-y>", toggle_my_branches)

				return true
			end,
		})
		:find()
end

function M.pick_branch()
	-- Start with local branches only
	create_picker(false, false)
end

return M
