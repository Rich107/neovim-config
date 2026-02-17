local M = {}

local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local entry_display = require("telescope.pickers.entry_display")

-- Get branches sorted by most recent commit with author and date
local function get_branches(include_remote)
	local flag = include_remote and "-a" or ""
	-- Format: branch name | author name | relative date
	local format = "%(refname:short)|%(authorname)|%(committerdate:relative)"
	local cmd = string.format("git branch %s --sort=-committerdate --format='%s'", flag, format)

	local result = vim.fn.systemlist(cmd)
	if vim.v.shell_error ~= 0 then
		return {}
	end

	local branches = {}
	for _, line in ipairs(result) do
		-- Skip HEAD pointer entries and empty lines
		if not line:match("HEAD") and line ~= "" then
			local branch, author, date = line:match("([^|]+)|([^|]*)|([^|]*)")
			if branch then
				table.insert(branches, {
					name = branch,
					author = author or "",
					date = date or "",
				})
			end
		end
	end

	return branches
end

local function create_picker(include_remote)
	local mode = include_remote and "All" or "Local"
	local toggle_hint = include_remote and "<C-a>: local only" or "<C-a>: include remote"
	local prompt_title = string.format("Git Branches [%s] (<CR>: checkout | <C-x>: delete | %s)", mode, toggle_hint)

	local branches = get_branches(include_remote)

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

					vim.cmd("Git checkout " .. vim.fn.shellescape(local_branch))
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
