local M = {}

local function split_nul(s)
	if not s or s == "" then
		return {}
	end
	-- Trim a single trailing NUL if present (common with -z output).
	if s:sub(-1) == "\0" then
		s = s:sub(1, -2)
	end
	if s == "" then
		return {}
	end
	local out = {}
	for piece in string.gmatch(s, "([^%z]+)") do
		table.insert(out, piece)
	end
	return out
end

M.get_git_diff_files = function(opts)
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

M.get_staged_files = function()
	local output = vim.fn.system("git diff --cached --name-only -z")
	if vim.v.shell_error ~= 0 then
		vim.notify("git-utils: failed to list staged files", vim.log.levels.ERROR)
		return nil
	end
	return split_nul(output)
end

M.get_unstaged_files = function()
	local output = vim.fn.system("git diff --name-only -z")
	if vim.v.shell_error ~= 0 then
		vim.notify("git-utils: failed to list unstaged files", vim.log.levels.ERROR)
		return nil
	end
	return split_nul(output)
end

return M
