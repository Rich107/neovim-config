local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local make_entry = require("telescope.make_entry")
local conf = require("telescope.config").values
local action_state = require("telescope.actions.state")
local test_globs = require("plugins.telescope.test-globs")

local M = {}

local MODES = { "all", "tests", "non-tests" }
local CYCLE_KEY = "<C-l>"

local function prompt_prefix_for(mode)
	return string.format("🔭 [%s] ", mode:upper())
end

local function title_for(mode)
	return string.format("Find Files — %s cycles mode (now: %s)", CYCLE_KEY, mode)
end

local function build_rg_args(mode)
	local args = { "rg", "--hidden", "--files" }
	if mode == "tests" then
		for _, a in ipairs(test_globs.include_args()) do
			table.insert(args, a)
		end
	elseif mode == "non-tests" then
		for _, a in ipairs(test_globs.exclude_args()) do
			table.insert(args, a)
		end
	end
	return args
end

local function make_finder(opts, mode)
	return finders.new_oneshot_job(build_rg_args(mode), opts)
end

local function find_files_test_aware(opts)
	opts = opts or {}
	opts.cwd = opts.cwd or vim.uv.cwd()
	opts.entry_maker = opts.entry_maker or make_entry.gen_from_file(opts)

	local mode_idx = 1

	local picker
	picker = pickers.new(opts, {
		prompt_title = title_for(MODES[mode_idx]),
		prompt_prefix = prompt_prefix_for(MODES[mode_idx]),
		default_text = opts.default_text,
		finder = make_finder(opts, MODES[mode_idx]),
		previewer = conf.file_previewer(opts),
		sorter = conf.file_sorter(opts),
		attach_mappings = function(prompt_bufnr, map)
			local function cycle_mode()
				mode_idx = (mode_idx % #MODES) + 1
				local mode = MODES[mode_idx]
				local current = action_state.get_current_picker(prompt_bufnr)

				-- Capture the user's typed text BEFORE we swap finders / prefix,
				-- using the picker's current prefix length so we strip exactly the prefix.
				local line = vim.api.nvim_buf_get_lines(prompt_bufnr, 0, 1, false)[1] or ""
				local typed = line:sub(#current.prompt_prefix + 1)

				-- Swap finder and prefix in one refresh call; the oneshot job re-runs
				-- immediately, regenerating the file list for the new mode. Fuzzy match
				-- against `typed` happens client-side via conf.file_sorter.
				current:refresh(make_finder(opts, mode), {
					reset_prompt = true,
					new_prefix = { prompt_prefix_for(mode), "TelescopePromptPrefix" },
				})
				current:reset_prompt(typed)

				if current.prompt_border and current.prompt_border.change_title then
					current.prompt_border:change_title(title_for(mode))
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
			map("i", CYCLE_KEY, cycle_mode)
			map("n", CYCLE_KEY, cycle_mode)
			return true
		end,
	})
	picker:find()
end

M.find_files_test_aware = find_files_test_aware

return M
