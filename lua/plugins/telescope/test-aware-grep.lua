local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local make_entry = require("telescope.make_entry")
local conf = require("telescope.config").values
local action_state = require("telescope.actions.state")
local sorters = require("telescope.sorters")

local M = {}

-- Globs that identify test files / test directories.
-- Used as include patterns in "tests" mode and as exclude patterns in "non-tests" mode.
local TEST_GLOBS = {
	-- JS / TS
	"**/*.test.*",
	"**/*.spec.*",
	"**/__tests__/**",
	"**/cypress/**",
	"**/e2e/**",
	-- Python
	"**/test_*.py",
	"**/*_test.py",
	"**/conftest.py",
	-- Go
	"**/*_test.go",
	-- Ruby
	"**/*_spec.rb",
	-- C# / Java / Kotlin
	"**/*Test.cs",
	"**/*Tests.cs",
	"**/*Test.java",
	"**/*Tests.java",
	"**/*Test.kt",
	"**/*Tests.kt",
	-- Generic directories
	"**/tests/**",
	"**/test/**",
	"**/spec/**",
	"**/specs/**",
}

local MODES = { "all", "tests", "non-tests" }
local CYCLE_KEY = "<C-l>"

local function prompt_prefix_for(mode)
	return string.format("🔭 [%s] ", mode:upper())
end

local function title_for(mode)
	return string.format("Live Grep — %s cycles mode (now: %s)", CYCLE_KEY, mode)
end

local function build_rg_args(prompt, mode)
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
		for _, g in ipairs(TEST_GLOBS) do
			table.insert(args, "-g")
			table.insert(args, g)
		end
	elseif mode == "non-tests" then
		for _, g in ipairs(TEST_GLOBS) do
			table.insert(args, "-g")
			table.insert(args, "!" .. g)
		end
	end
	return args
end

local function make_finder(opts, mode)
	return finders.new_async_job({
		command_generator = function(prompt)
			return build_rg_args(prompt, mode)
		end,
		entry_maker = make_entry.gen_from_vimgrep(opts),
		cwd = opts.cwd,
	})
end

local function live_grep_test_aware(opts)
	opts = opts or {}
	opts.cwd = opts.cwd or vim.uv.cwd()

	local mode_idx = 1

	local picker
	picker = pickers.new(opts, {
		debounce = 100,
		prompt_title = title_for(MODES[mode_idx]),
		prompt_prefix = prompt_prefix_for(MODES[mode_idx]),
		default_text = opts.default_text,
		finder = make_finder(opts, MODES[mode_idx]),
		previewer = conf.grep_previewer(opts),
		sorter = sorters.empty(),
		attach_mappings = function(prompt_bufnr, map)
			local function cycle_mode()
				mode_idx = (mode_idx % #MODES) + 1
				local mode = MODES[mode_idx]
				local current = action_state.get_current_picker(prompt_bufnr)
				current:refresh(make_finder(opts, mode), { reset_prompt = false })
				current:change_prompt_prefix(prompt_prefix_for(mode), "TelescopePromptPrefix")
				if current.prompt_border and current.prompt_border.change_title then
					current.prompt_border:change_title(title_for(mode))
				end
			end
			map("i", CYCLE_KEY, cycle_mode)
			map("n", CYCLE_KEY, cycle_mode)
			return true
		end,
	})
	picker:find()
end

M.live_grep_test_aware = live_grep_test_aware

return M
