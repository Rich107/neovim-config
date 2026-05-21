local M = {}

local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local entry_display = require("telescope.pickers.entry_display")

-- Test ID attribute patterns to search for (Lua patterns use % for escaping)
local TEST_ID_ATTRIBUTES_LUA = {
	"data%-testid",
	"data%-test%-id",
	"data%-test",
	"data%-cy",
	"data%-pw",
}

-- Test ID attribute patterns for ripgrep regex (uses standard regex)
local TEST_ID_ATTRIBUTES_RG = {
	"data-testid",
	"data-test-id",
	"data-test",
	"data-cy",
	"data-pw",
}

-- File extensions to search
local FILE_EXTENSIONS = {
	"js",
	"jsx",
	"ts",
	"tsx",
	"vue",
	"svelte",
	"html",
	"py", -- Python templates (Jinja2, etc.)
}

-- Test file patterns to identify test files
local TEST_FILE_PATTERNS = {
	"%.spec%.",
	"%.test%.",
	"_test%.py$",
	"^test_.*%.py$",
	"__tests__/",
	"/tests/",
	"/test/",
}

-- Filter modes
local FILTER_MODES = {
	"implementation", -- exclude test files (default)
	"all", -- show all files
	"tests", -- only test files
}

local function is_test_file(filepath)
	for _, pattern in ipairs(TEST_FILE_PATTERNS) do
		if filepath:match(pattern) then
			return true
		end
	end
	return false
end

local function escape_regex(str)
	-- Escape special regex characters for ripgrep
	return str:gsub("([%.%+%*%?%^%$%(%)%[%]%{%}%|\\])", "\\%1")
end

local function build_rg_command()
	-- Build the regex pattern to match test ID attributes with values in quotes
	-- Matches: data-testid="value" or data-testid='value' or data-testid={`value`} or data-testid={value}
	local attr_pattern = table.concat(TEST_ID_ATTRIBUTES_RG, "|")
	-- Pattern matches the attribute and captures everything up to the closing quote/brace
	-- Using standard regex (no PCRE2 required)
	local pattern = "(" .. attr_pattern .. ")=[\"'`{][^\"'`}]+"

	local cmd = {
		"rg",
		"--color=never",
		"--no-heading",
		"--with-filename",
		"--line-number",
		"--column",
		"-o", -- only output the match
		pattern,
	}

	-- Add glob patterns for file extensions
	for _, ext in ipairs(FILE_EXTENSIONS) do
		table.insert(cmd, string.format("--glob=*.%s", ext))
	end

	return cmd
end

local function parse_rg_output(line)
	-- Parse ripgrep output: filename:line:column:match
	local filepath, lnum, col, match = line:match("^(.+):(%d+):(%d+):(.+)$")
	if not filepath then
		return nil
	end

	-- Extract the test ID value from the match
	-- Match is like: data-testid="some-value" or data-testid='some-value' or data-testid={`some-value`}
	-- Extract value between quotes/braces after the =
	local testid = match:match('=["\'{`]([^"\'}`]+)')
	if not testid then
		-- Fallback: try to get everything after the =
		testid = match:match("=(.+)$")
		if testid then
			-- Remove surrounding quotes/braces
			testid = testid:gsub('^["\'{`]', ""):gsub('["\'}`]$', "")
		end
	end

	return {
		filepath = filepath,
		lnum = tonumber(lnum),
		col = tonumber(col),
		match = match,
		testid = testid or match,
		is_test = is_test_file(filepath),
	}
end

local function get_all_testids()
	local cmd = build_rg_command()
	local result = vim.fn.systemlist(cmd)

	if vim.v.shell_error ~= 0 and #result == 0 then
		return {}
	end

	local entries = {}
	for _, line in ipairs(result) do
		local parsed = parse_rg_output(line)
		if parsed then
			table.insert(entries, parsed)
		end
	end

	return entries
end

local function filter_entries(entries, mode)
	if mode == "all" then
		return entries
	end

	local filtered = {}
	for _, entry in ipairs(entries) do
		if mode == "implementation" and not entry.is_test then
			table.insert(filtered, entry)
		elseif mode == "tests" and entry.is_test then
			table.insert(filtered, entry)
		end
	end
	return filtered
end

local function get_mode_display(mode)
	if mode == "implementation" then
		return "Implementation"
	elseif mode == "all" then
		return "All files"
	elseif mode == "tests" then
		return "Tests only"
	end
	return mode
end

local function cycle_mode(current_mode)
	for i, mode in ipairs(FILTER_MODES) do
		if mode == current_mode then
			return FILTER_MODES[(i % #FILTER_MODES) + 1]
		end
	end
	return FILTER_MODES[1]
end

local function create_picker(all_entries, current_mode)
	local filtered_entries = filter_entries(all_entries, current_mode)

	local prompt_title = string.format(
		"Test IDs [%s] | <C-a>: cycle filter | <C-q>: quickfix",
		get_mode_display(current_mode)
	)

	-- Calculate max widths for alignment
	local max_testid_len = 30
	local max_filepath_len = 40
	for _, entry in ipairs(filtered_entries) do
		max_testid_len = math.max(max_testid_len, #entry.testid)
		max_filepath_len = math.max(max_filepath_len, #entry.filepath)
	end
	max_testid_len = math.min(max_testid_len, 50)
	max_filepath_len = math.min(max_filepath_len, 60)

	local displayer = entry_display.create({
		separator = " ",
		items = {
			{ width = max_testid_len },
			{ width = max_filepath_len },
			{ remaining = true },
		},
	})

	local make_display = function(entry)
		local icon = entry.value.is_test and "[T]" or "[I]"
		return displayer({
			{ entry.value.testid, "TelescopeResultsIdentifier" },
			{ entry.value.filepath, "TelescopeResultsComment" },
			{ string.format("%s:%d %s", "", entry.value.lnum, icon), "TelescopeResultsNumber" },
		})
	end

	-- Use Telescope's built-in grep previewer which handles file preview with line highlighting
	local previewer = conf.grep_previewer({})

	pickers
		.new({}, {
			prompt_title = prompt_title,
			finder = finders.new_table({
				results = filtered_entries,
				entry_maker = function(entry)
					return {
						value = entry,
						display = make_display,
						ordinal = entry.testid,
						filename = entry.filepath,
						lnum = entry.lnum,
						col = entry.col,
					}
				end,
			}),
			sorter = conf.generic_sorter({}),
			previewer = previewer,
			attach_mappings = function(prompt_bufnr, map)
				-- Open file at line on enter
				actions.select_default:replace(function()
					local selection = action_state.get_selected_entry()
					if not selection then
						return
					end
					actions.close(prompt_bufnr)
					vim.cmd("edit " .. selection.value.filepath)
					vim.api.nvim_win_set_cursor(0, { selection.value.lnum, selection.value.col - 1 })
				end)

				-- Send to quickfix with Ctrl+q
				local function send_to_quickfix()
					local picker = action_state.get_current_picker(prompt_bufnr)
					local entries = picker:get_multi_selection()

					-- If no multi-selection, use all filtered results
					if #entries == 0 then
						local manager = picker.manager
						for item in manager:iter() do
							table.insert(entries, item)
						end
					end

					local qf_entries = {}
					for _, entry in ipairs(entries) do
						table.insert(qf_entries, {
							filename = entry.value.filepath,
							lnum = entry.value.lnum,
							col = entry.value.col,
							text = entry.value.testid .. " | " .. entry.value.match,
						})
					end

					actions.close(prompt_bufnr)
					vim.fn.setqflist(qf_entries)
					vim.cmd("copen")
				end

				-- Cycle filter mode with Ctrl+a
				local function toggle_filter()
					local current_line = action_state.get_current_line()
					actions.close(prompt_bufnr)
					vim.schedule(function()
						local new_mode = cycle_mode(current_mode)
						create_picker(all_entries, new_mode)
						if current_line and current_line ~= "" then
							vim.schedule(function()
								vim.api.nvim_feedkeys(current_line, "n", false)
							end)
						end
					end)
				end

				map("i", "<C-a>", toggle_filter)
				map("n", "<C-a>", toggle_filter)
				map("i", "<C-q>", send_to_quickfix)
				map("n", "<C-q>", send_to_quickfix)

				return true
			end,
		})
		:find()
end

function M.find_testids()
	-- Show loading message
	vim.notify("Searching for test IDs...", vim.log.levels.INFO)

	-- Run search asynchronously to not block UI
	vim.schedule(function()
		local all_entries = get_all_testids()

		if #all_entries == 0 then
			vim.notify("No test IDs found in the codebase", vim.log.levels.WARN)
			return
		end

		vim.notify(string.format("Found %d test IDs", #all_entries), vim.log.levels.INFO)
		create_picker(all_entries, "implementation")
	end)
end

M.setup = function()
	vim.keymap.set("n", "<leader>ft", M.find_testids, { desc = "Find Test IDs" })
end

return M
