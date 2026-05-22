local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local make_entry = require("telescope.make_entry")
local conf = require("telescope.config").values
local action_state = require("telescope.actions.state")
local sorters = require("telescope.sorters")
local git_utils = require("plugins.telescope.git-utils")

local M = {}

local MODES = { "all", "changed", "staged", "unstaged" }
local CYCLE_KEY = "<C-l>"

local function prompt_prefix_for(mode)
	return string.format("🔭 [%s] ", mode:upper())
end

local function title_for(mode)
	return string.format("Git-Status Grep — %s cycles (now: %s)", CYCLE_KEY, mode)
end

-- Returns:
--   files: list of file paths (or nil for `all` mode meaning "no restriction")
--   ok: boolean — false means we couldn't resolve a non-empty file set
local function resolve_files(mode, opts)
	if mode == "all" then
		return nil, true
	elseif mode == "changed" then
		local files = git_utils.get_git_diff_files(opts)
		if not files or #files == 0 then
			return nil, false
		end
		return files, true
	elseif mode == "staged" then
		local files = git_utils.get_staged_files()
		if not files or #files == 0 then
			return nil, false
		end
		return files, true
	elseif mode == "unstaged" then
		local files = git_utils.get_unstaged_files()
		if not files or #files == 0 then
			return nil, false
		end
		return files, true
	end
	return nil, false
end

local function build_rg_args(prompt, files)
	if not prompt or prompt == "" then
		return nil
	end
	local args = {
		"rg",
		"--color=never",
		"--no-heading",
		"--with-filename",
		"--line-number",
		"--column",
		"--smart-case",
		"-e",
		prompt,
	}
	if files and #files > 0 then
		table.insert(args, "--")
		for _, f in ipairs(files) do
			table.insert(args, f)
		end
	end
	return args
end

local function make_finder(opts, files)
	return finders.new_async_job({
		command_generator = function(prompt)
			return build_rg_args(prompt, files)
		end,
		entry_maker = make_entry.gen_from_vimgrep(opts),
		cwd = opts.cwd,
	})
end

local function git_status_grep(opts)
	opts = opts or {}
	opts.cwd = opts.cwd or vim.uv.cwd()

	local mode_idx = 1
	local mode = MODES[mode_idx]
	local files, ok = resolve_files(mode, opts)
	if not ok then
		vim.notify(
			"git-status-grep: no " .. mode .. " files; staying on previous mode",
			vim.log.levels.WARN
		)
		-- For initial open, fall back to `all` so the picker still opens.
		files = nil
	end

	local picker
	picker = pickers.new(opts, {
		debounce = 100,
		prompt_title = title_for(mode),
		prompt_prefix = prompt_prefix_for(mode),
		default_text = opts.default_text,
		finder = make_finder(opts, files),
		previewer = conf.grep_previewer(opts),
		sorter = sorters.empty(),
		attach_mappings = function(prompt_bufnr, map)
			local function cycle_mode()
				local next_idx = (mode_idx % #MODES) + 1
				local next_mode = MODES[next_idx]
				local new_files, new_ok = resolve_files(next_mode, opts)
				if not new_ok then
					vim.notify(
						"git-status-grep: no " .. next_mode .. " files; staying on previous mode",
						vim.log.levels.WARN
					)
					return
				end

				mode_idx = next_idx
				local current = action_state.get_current_picker(prompt_bufnr)

				-- Capture typed text BEFORE swapping prefix.
				local line = vim.api.nvim_buf_get_lines(prompt_bufnr, 0, 1, false)[1] or ""
				local typed = line:sub(#current.prompt_prefix + 1)

				current:refresh(make_finder(opts, new_files), {
					reset_prompt = true,
					new_prefix = { prompt_prefix_for(next_mode), "TelescopePromptPrefix" },
				})
				current:reset_prompt(typed)

				if current.prompt_border and current.prompt_border.change_title then
					current.prompt_border:change_title(title_for(next_mode))
				end

				vim.defer_fn(function()
					if current and current.refresh_previewer then
						pcall(function()
							current:refresh_previewer()
						end)
					end
				end, 80)
			end
			map("i", CYCLE_KEY, cycle_mode)
			map("n", CYCLE_KEY, cycle_mode)
			return true
		end,
	})
	picker:find()
end

M.git_status_grep = git_status_grep

return M
