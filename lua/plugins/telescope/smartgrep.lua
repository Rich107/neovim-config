local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local make_entry = require("telescope.make_entry")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")

local M = {}

local get_git_diff_files = function(opts)
	opts = opts or {}
	local cwd = opts.cwd or vim.loop.cwd()

	local remote_branches_cmd = "git branch -r"
	local remote_branches_output = vim.fn.system(remote_branches_cmd)
	local remote_branches = vim.split(remote_branches_output, "\n")

	local primary_branch
	for _, branch in ipairs(remote_branches) do
		branch = branch:gsub("^%s+", "") -- Trim leading whitespace
		if branch == "origin/main" or branch == "origin/master" or branch == "origin/production" then
			primary_branch = branch
			break
		end
	end

	if not primary_branch then
		vim.notify("No primary branch (main, master, or production) found on remote 'origin'.", vim.log.levels.ERROR)
		return
	end

	local git_diff_command = "git diff --name-only " .. primary_branch .. "..."
	local files = vim.fn.systemlist(git_diff_command)

	return files
end

local diff_files_picker = function(opts)
	opts = opts or {}
	opts.results = get_git_diff_files(opts)

	if not opts.results or #opts.results == 0 then
		vim.notify("No changed files found.", vim.log.levels.INFO)
		return
	end

	pickers
		.new(opts, {
			prompt_title = "Changed Files",
			finder = finders.new_table({
				results = opts.results,
				entry_maker = function(entry)
					return {
						value = entry,
						display = entry,
						ordinal = entry,
					}
				end,
			}),
			sorter = conf.generic_sorter(opts),
			attach_mappings = function(prompt_bufnr, map)
				actions.select_default:replace(function()
					actions.close(prompt_bufnr)
					local selection = action_state.get_selected_entry()
					vim.cmd("edit " .. selection.value)
				end)
				return true
			end,
		})
		:find()
end

local live_smartgrep = function(opts)
	opts = opts or {}
	opts.cwd = opts.cwd or vim.uv.cwd()

	local finder = finders.new_async_job({
		command_generator = function(prompt)
			if not prompt or prompt == "" then
				return nil
			end

			local pieces = vim.split(prompt, "  ")
			local args = { "rg" }
			if pieces[1] then
				table.insert(args, "-e")
				table.insert(args, pieces[1])
			end

			if pieces[2] then
				table.insert(args, "-g")
				table.insert(args, pieces[2])
			end

			return vim.tbl_flatten({
				args,
				{ "--color=never", "--no-heading", "--with-filename", "--line-number", "--column", "--smart-case" },
			})
		end,
		entry_maker = make_entry.gen_from_vimgrep(opts),
		cwd = opts.cwd,
	})
	pickers
		.new(opts, {
			debounce = 100,
			prompt_title = "Smart Grep",
			finder = finder,
			previewer = conf.grep_previewer(opts),
			sorter = require("telescope.sorters").empty(),
		})
		:find()
end

M.diff_files_picker = diff_files_picker

M.setup = function()
	vim.keymap.set("n", "<leader>tg", live_smartgrep, { desc = "Smart Search" })
	vim.keymap.set("n", "<leader>fd", diff_files_picker, { desc = "Diff Files" })
end

-- live_smartgrep()

return M
