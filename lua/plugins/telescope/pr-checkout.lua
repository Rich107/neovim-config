local M = {}

function M.checkout_pr_by_label_prefix()
	local pickers = require("telescope.pickers")
	local finders = require("telescope.finders")
	local conf = require("telescope.config").values
	local actions = require("telescope.actions")
	local action_state = require("telescope.actions.state")

	-- Prompt user for label prefix
	vim.ui.input({ prompt = "Enter label prefix: " }, function(label_prefix)
		if not label_prefix or label_prefix == "" then
			vim.notify("Label prefix is required", vim.log.levels.ERROR)
			return
		end

		-- Get all labels from the repo that match the prefix
		local cmd = string.format(
			"gh label list --limit 1000 --json name --jq '.[] | select(.name | startswith(\"%s\")) | .name'",
			label_prefix
		)

		local handle = io.popen(cmd)
		if not handle then
			vim.notify("Failed to fetch labels", vim.log.levels.ERROR)
			return
		end

		local labels = {}
		for line in handle:lines() do
			if line and line ~= "" then
				table.insert(labels, line)
			end
		end
		handle:close()

		if #labels == 0 then
			vim.notify("No labels found matching prefix: " .. label_prefix, vim.log.levels.WARN)
			return
		end

		-- If only one label matches, use it directly
		if #labels == 1 then
			vim.notify("Found label: " .. labels[1], vim.log.levels.INFO)
			M.show_prs_for_checkout(labels[1])
			return
		end

		-- Multiple labels found, show picker
		vim.notify(string.format("Found %d matching labels", #labels), vim.log.levels.INFO)

		pickers
			.new({}, {
				prompt_title = "Select Label (prefix: " .. label_prefix .. ")",
				finder = finders.new_table({
					results = labels,
					entry_maker = function(entry)
						return {
							value = entry,
							display = entry,
							ordinal = entry,
						}
					end,
				}),
				sorter = conf.generic_sorter({}),
				attach_mappings = function(prompt_bufnr, _)
					actions.select_default:replace(function()
						local selection = action_state.get_selected_entry()
						actions.close(prompt_bufnr)
						M.show_prs_for_checkout(selection.value)
					end)
					return true
				end,
			})
			:find()
	end)
end

function M.show_prs_for_checkout(label)
	local pickers = require("telescope.pickers")
	local finders = require("telescope.finders")
	local conf = require("telescope.config").values
	local actions = require("telescope.actions")
	local action_state = require("telescope.actions.state")
	local previewers = require("telescope.previewers")

	vim.notify("Finding PRs with label: " .. label, vim.log.levels.INFO)

	-- Get PRs with the selected label
	local cmd = string.format(
		'gh pr list --label "%s" --limit 1000 --json number,title,author,headRefName,body --jq \'.[] | "\\(.number)\\t\\(.title)\\t\\(.author.login)\\t\\(.headRefName)\\t\\(.body // "")"\'',
		label
	)

	local handle = io.popen(cmd)
	if not handle then
		vim.notify("Failed to fetch PRs", vim.log.levels.ERROR)
		return
	end

	local prs = {}
	for line in handle:lines() do
		local number, title, author, branch, body = line:match("([^\t]+)\t([^\t]+)\t([^\t]+)\t([^\t]+)\t?(.*)")
		if number then
			table.insert(prs, {
				number = number,
				title = title,
				author = author,
				branch = branch,
				body = body or "",
				display = string.format("#%-5s %-50s (by %s)", number, title:sub(1, 50), author),
			})
		end
	end
	handle:close()

	if #prs == 0 then
		vim.notify("No open PRs found with label: " .. label, vim.log.levels.WARN)
		return
	end

	vim.notify(string.format("Found %d PR(s)", #prs), vim.log.levels.INFO)

	pickers
		.new({}, {
			prompt_title = "Select PR to Checkout (label: " .. label .. ")",
			finder = finders.new_table({
				results = prs,
				entry_maker = function(entry)
					return {
						value = entry,
						display = entry.display,
						ordinal = entry.number .. " " .. entry.title .. " " .. entry.author,
					}
				end,
			}),
			sorter = conf.generic_sorter({}),
			previewer = previewers.new_buffer_previewer({
				title = "PR Details",
				define_preview = function(self, entry, _)
					local pr = entry.value
					local lines = {
						"PR #" .. pr.number .. ": " .. pr.title,
						"Author: " .. pr.author,
						"Branch: " .. pr.branch,
						"",
						"Description:",
						string.rep("─", 50),
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

					local pr = selection.value
					vim.notify(
						string.format(
							"Selected PR #%s: %s\nAuthor: %s\nBranch: %s",
							pr.number,
							pr.title,
							pr.author,
							pr.branch
						),
						vim.log.levels.INFO
					)

					-- Check if branch exists locally
					local check_branch = vim.fn.system(
						string.format('git rev-parse --verify "%s" 2>/dev/null', pr.branch)
					)
					local branch_exists = vim.v.shell_error == 0

					local checkout_cmd
					if branch_exists then
						vim.notify("Checking out existing local branch: " .. pr.branch, vim.log.levels.INFO)
						checkout_cmd = string.format('git checkout "%s" && git pull origin "%s"', pr.branch, pr.branch)
					else
						vim.notify("Fetching and checking out branch: " .. pr.branch, vim.log.levels.INFO)
						checkout_cmd = string.format(
							'git fetch origin "%s:%s" && git checkout "%s"',
							pr.branch,
							pr.branch,
							pr.branch
						)
					end

					-- Execute checkout command
					vim.fn.jobstart(checkout_cmd, {
						on_exit = function(_, code)
							if code == 0 then
								vim.schedule(function()
									vim.notify(
										string.format(
											"Successfully checked out PR #%s\nYou are now on branch: %s",
											pr.number,
											pr.branch
										),
										vim.log.levels.INFO
									)
									-- Reload the buffer to reflect changes
									vim.cmd("checktime")
								end)
							else
								vim.schedule(function()
									vim.notify(
										"Failed to checkout PR #" .. pr.number .. ". Check git output for details.",
										vim.log.levels.ERROR
									)
								end)
							end
						end,
						on_stdout = function(_, data)
							if data then
								vim.schedule(function()
									for _, line in ipairs(data) do
										if line ~= "" then
											print(line)
										end
									end
								end)
							end
						end,
						on_stderr = function(_, data)
							if data then
								vim.schedule(function()
									for _, line in ipairs(data) do
										if line ~= "" then
											print(line)
										end
									end
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
