local M = {}

-- Helper function to get CI status for a PR
local function get_ci_status(pr_number)
	local handle = io.popen(string.format('gh pr view %s --json statusCheckRollup 2>/dev/null', pr_number))
	if not handle then
		return nil, ""
	end
	
	local output = handle:read("*a")
	handle:close()
	
	if not output or output == "" then
		return nil, ""
	end
	
	-- Parse the JSON to check for status checks
	local has_checks = output:match('"statusCheckRollup":%[.-%]')
	if not has_checks or output:match('"statusCheckRollup":%[%]') then
		-- No checks configured or empty array
		return nil, ""
	end
	
	-- Count different states
	local success_count = select(2, output:gsub('"state":"SUCCESS"', ''))
	local failure_count = select(2, output:gsub('"state":"FAILURE"', ''))
	local pending_count = select(2, output:gsub('"state":"PENDING"', ''))
	local error_count = select(2, output:gsub('"state":"ERROR"', ''))
	
	if failure_count > 0 or error_count > 0 then
		return "failing", "✗ "
	elseif pending_count > 0 then
		return "pending", "◐ "
	elseif success_count > 0 then
		return "passing", "✓ "
	end
	
	return nil, ""
end

function M.pick_open_pr()
	local pickers = require("telescope.pickers")
	local finders = require("telescope.finders")
	local conf = require("telescope.config").values
	local actions = require("telescope.actions")
	local action_state = require("telescope.actions.state")
	local previewers = require("telescope.previewers")

	-- Get all open PRs
	local cmd = 'gh pr list --state open --json number,title,author,headRefName,state,body --jq \'.[] | "\\(.number)\\t\\(.title)\\t\\(.author.login)\\t\\(.headRefName)\\t\\(.state)\\t\\(.body // "")\"\''

	local handle = io.popen(cmd)
	if not handle then
		vim.notify("Failed to fetch PRs", vim.log.levels.ERROR)
		return
	end

	local prs = {}
	for line in handle:lines() do
		local number, title, author, branch, state, body = line:match("([^\t]+)\t([^\t]+)\t([^\t]+)\t([^\t]+)\t([^\t]+)\t?(.*)")
		if number then
			-- Get CI status for this PR
			local ci_status, ci_icon = get_ci_status(number)
			
			-- Only show icon if we have actual CI status
			local display_text = ci_icon ~= "" 
				and string.format("#%s %s%s (%s)", number, ci_icon, title, author)
				or string.format("#%s %s (%s)", number, title, author)
			
			table.insert(prs, {
				number = number,
				title = title,
				author = author,
				branch = branch,
				state = state,
				body = body or "",
				ci_status = ci_status,
				ci_icon = ci_icon,
				display = display_text,
			})
		end
	end
	handle:close()

	if #prs == 0 then
		vim.notify("No open PRs found", vim.log.levels.WARN)
		return
	end

	pickers
		.new({}, {
			prompt_title = "Open Pull Requests",
			finder = finders.new_table({
				results = prs,
				entry_maker = function(entry)
					return {
						value = entry,
						display = entry.display,
						ordinal = entry.number .. " " .. entry.title .. " " .. entry.author .. " " .. entry.branch,
					}
				end,
			}),
			sorter = conf.generic_sorter({}),
			previewer = previewers.new_buffer_previewer({
				title = "PR Details",
				define_preview = function(self, entry, _)
					local pr = entry.value
					local lines = {
						"PR #" .. pr.number,
						"Title: " .. pr.title,
						"Author: " .. pr.author,
						"Branch: " .. pr.branch,
						"State: " .. pr.state,
					}
					
					-- Only show CI status if it exists
					if pr.ci_status then
						local ci_display = pr.ci_icon .. pr.ci_status:upper()
						table.insert(lines, "CI Status: " .. ci_display)
					end
					
					table.insert(lines, "")
					table.insert(lines, "Description:")
					table.insert(lines, string.rep("-", 40))

					if pr.body and pr.body ~= "" then
						for _, body_line in ipairs(vim.split(pr.body, "\n")) do
							table.insert(lines, body_line)
						end
					else
						table.insert(lines, "(No description)")
					end

					vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
					vim.api.nvim_buf_set_option(self.state.bufnr, "filetype", "markdown")
				end,
			}),
			attach_mappings = function(prompt_bufnr, map)
				actions.select_default:replace(function()
					local selection = action_state.get_selected_entry()
					actions.close(prompt_bufnr)

					-- Checkout the PR branch
					local branch = selection.value.branch
					vim.notify("Checking out branch: " .. branch, vim.log.levels.INFO)

					-- Use gh pr checkout which handles both local and remote branches
					vim.fn.jobstart(string.format("gh pr checkout %s", selection.value.number), {
						on_exit = function(_, code)
							if code == 0 then
								vim.schedule(function()
									vim.notify("Checked out PR #" .. selection.value.number .. " (" .. branch .. ")", vim.log.levels.INFO)
									-- Reload the buffer to reflect changes
									vim.cmd("checktime")
								end)
							else
								vim.schedule(function()
									vim.notify("Failed to checkout PR #" .. selection.value.number, vim.log.levels.ERROR)
								end)
							end
						end,
					})
				end)

				-- Open PR in browser
				map("i", "<C-o>", function()
					local selection = action_state.get_selected_entry()
					vim.fn.jobstart(string.format("gh pr view %s --web", selection.value.number))
				end)

				return true
			end,
		})
		:find()
end

return M
