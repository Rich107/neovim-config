local M = {}

function M.pick_pr_by_label()
	local pickers = require("telescope.pickers")
	local finders = require("telescope.finders")
	local conf = require("telescope.config").values
	local actions = require("telescope.actions")
	local action_state = require("telescope.actions.state")

	-- Get labels from the repo (--limit 100 to get more than default 30)
	local handle = io.popen("gh label list --limit 100 --json name,description --jq '.[] | .name + \"\\t\" + (.description // \"\")'")
	if not handle then
		vim.notify("Failed to fetch labels", vim.log.levels.ERROR)
		return
	end

	local labels = {}
	for line in handle:lines() do
		local name, desc = line:match("([^\t]+)\t?(.*)")
		if name then
			table.insert(labels, {
				name = name,
				description = desc or "",
				display = desc and desc ~= "" and string.format("%s - %s", name, desc) or name,
			})
		end
	end
	handle:close()

	if #labels == 0 then
		vim.notify("No labels found in repository", vim.log.levels.WARN)
		return
	end

	pickers
		.new({}, {
			prompt_title = "Select Label to Filter PRs",
			finder = finders.new_table({
				results = labels,
				entry_maker = function(entry)
					return {
						value = entry,
						display = entry.display,
						ordinal = entry.name .. " " .. entry.description,
					}
				end,
			}),
			sorter = conf.generic_sorter({}),
			attach_mappings = function(prompt_bufnr, _)
				actions.select_default:replace(function()
					local selection = action_state.get_selected_entry()
					actions.close(prompt_bufnr)

					-- Now show PRs with this label
					M.show_prs_with_label(selection.value.name)
				end)
				return true
			end,
		})
		:find()
end

function M.show_prs_with_label(label)
	local pickers = require("telescope.pickers")
	local finders = require("telescope.finders")
	local conf = require("telescope.config").values
	local actions = require("telescope.actions")
	local action_state = require("telescope.actions.state")
	local previewers = require("telescope.previewers")

	-- Get PRs with the selected label
	local cmd = string.format(
		'gh pr list --label "%s" --json number,title,author,headRefName,state,body --jq \'.[] | "\\(.number)\\t\\(.title)\\t\\(.author.login)\\t\\(.headRefName)\\t\\(.state)\\t\\(.body // "")"\'',
		label
	)

	local handle = io.popen(cmd)
	if not handle then
		vim.notify("Failed to fetch PRs", vim.log.levels.ERROR)
		return
	end

	local prs = {}
	for line in handle:lines() do
		local number, title, author, branch, state, body = line:match("([^\t]+)\t([^\t]+)\t([^\t]+)\t([^\t]+)\t([^\t]+)\t?(.*)")
		if number then
			table.insert(prs, {
				number = number,
				title = title,
				author = author,
				branch = branch,
				state = state,
				body = body or "",
				display = string.format("#%s %s (%s)", number, title, author),
			})
		end
	end
	handle:close()

	if #prs == 0 then
		vim.notify("No PRs found with label: " .. label, vim.log.levels.WARN)
		return
	end

	pickers
		.new({}, {
			prompt_title = "PRs with label: " .. label,
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
						"",
						"Description:",
						string.rep("-", 40),
					}

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
