local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local make_entry = require("telescope.make_entry")
local conf = require("telescope.config").values
local action_state = require("telescope.actions.state")
local sorters = require("telescope.sorters")
local test_globs = require("plugins.telescope.test-globs")

local M = {}

local MODES = { "all", "tests", "non-tests" }
local MODE_KEY = "<C-l>"

local SCOPES = { "cwd", "buffers", "current" }
local SCOPE_KEY = "<C-s>"

local function prompt_prefix_for(mode, scope)
	return string.format("🔭 [%s|%s] ", mode:upper(), scope:upper())
end

local function title_for(mode, scope)
	return string.format(
		"Live Grep — %s mode, %s scope (now: %s | %s)",
		MODE_KEY,
		SCOPE_KEY,
		mode,
		scope
	)
end

local function collect_buffer_files()
	local files = {}
	for _, buf in ipairs(vim.api.nvim_list_bufs()) do
		if vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].buflisted then
			local name = vim.api.nvim_buf_get_name(buf)
			if name and name ~= "" then
				local stat = vim.uv.fs_stat(name)
				if stat and stat.type == "file" then
					table.insert(files, name)
				end
			end
		end
	end
	return files
end

local function build_rg_args(prompt, mode, scope)
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
	if mode == "tests" then
		for _, a in ipairs(test_globs.include_args()) do
			table.insert(args, a)
		end
	elseif mode == "non-tests" then
		for _, a in ipairs(test_globs.exclude_args()) do
			table.insert(args, a)
		end
	end

	if scope == "buffers" then
		local files = collect_buffer_files()
		if #files > 0 then
			table.insert(args, "--")
			for _, f in ipairs(files) do
				table.insert(args, f)
			end
		end
	elseif scope == "current" then
		local name = vim.api.nvim_buf_get_name(0)
		if name and name ~= "" then
			local stat = vim.uv.fs_stat(name)
			if stat and stat.type == "file" then
				table.insert(args, "--")
				table.insert(args, name)
			end
		end
	end

	return args
end

local function make_finder(opts, mode, scope)
	return finders.new_async_job({
		command_generator = function(prompt)
			return build_rg_args(prompt, mode, scope)
		end,
		entry_maker = make_entry.gen_from_vimgrep(opts),
		cwd = opts.cwd,
	})
end

local function live_grep_test_aware(opts)
	opts = opts or {}
	opts.cwd = opts.cwd or vim.uv.cwd()

	local mode_idx = 1
	local scope_idx = 1

	local picker
	picker = pickers.new(opts, {
		debounce = 100,
		prompt_title = title_for(MODES[mode_idx], SCOPES[scope_idx]),
		prompt_prefix = prompt_prefix_for(MODES[mode_idx], SCOPES[scope_idx]),
		default_text = opts.default_text,
		finder = make_finder(opts, MODES[mode_idx], SCOPES[scope_idx]),
		previewer = conf.grep_previewer(opts),
		sorter = sorters.empty(),
		attach_mappings = function(prompt_bufnr, map)
			local function apply_change(mode, scope)
				local current = action_state.get_current_picker(prompt_bufnr)

				-- Capture the user's typed text BEFORE we swap finders / prefix,
				-- using the picker's current prefix length so we strip exactly the prefix.
				local line = vim.api.nvim_buf_get_lines(prompt_bufnr, 0, 1, false)[1] or ""
				local typed = line:sub(#current.prompt_prefix + 1)

				-- Swap finder and prefix in one refresh call; reset_prompt=true rebuilds
				-- the prompt line as `new_prefix .. typed`, which keeps the typed text and
				-- forces the new finder's command_generator to fire for that prompt.
				current:refresh(make_finder(opts, mode, scope), {
					reset_prompt = true,
					new_prefix = { prompt_prefix_for(mode, scope), "TelescopePromptPrefix" },
				})
				current:reset_prompt(typed)

				if current.prompt_border and current.prompt_border.change_title then
					current.prompt_border:change_title(title_for(mode, scope))
				end

				-- Refresh the previewer once the new first entry has been selected.
				vim.defer_fn(function()
					if current and current.refresh_previewer then
						pcall(function()
							current:refresh_previewer()
						end)
					end
				end, 80)
			end

			local function cycle_mode()
				mode_idx = (mode_idx % #MODES) + 1
				apply_change(MODES[mode_idx], SCOPES[scope_idx])
			end

			local function cycle_scope()
				local next_idx = (scope_idx % #SCOPES) + 1
				local next_scope = SCOPES[next_idx]

				if next_scope == "buffers" then
					if #collect_buffer_files() == 0 then
						vim.notify(
							"No file-backed buffers; staying on previous scope",
							vim.log.levels.WARN
						)
						return
					end
				elseif next_scope == "current" then
					local name = vim.api.nvim_buf_get_name(0)
					local ok = false
					if name and name ~= "" then
						local stat = vim.uv.fs_stat(name)
						if stat and stat.type == "file" then
							ok = true
						end
					end
					if not ok then
						vim.notify(
							"No file-backed buffers; staying on previous scope",
							vim.log.levels.WARN
						)
						return
					end
				end

				scope_idx = next_idx
				apply_change(MODES[mode_idx], SCOPES[scope_idx])
			end

			map("i", MODE_KEY, cycle_mode)
			map("n", MODE_KEY, cycle_mode)
			map("i", SCOPE_KEY, cycle_scope)
			map("n", SCOPE_KEY, cycle_scope)
			return true
		end,
	})
	picker:find()
end

M.live_grep_test_aware = live_grep_test_aware

return M
