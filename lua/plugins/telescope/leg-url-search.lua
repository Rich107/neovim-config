local M = {}

local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local previewers = require("telescope.previewers")

-- Parse a single line from show_urls output
local function parse_url_line(line, urlconf_name)
	line = line:strip()
	if not line or line == "" or not line:match("^/") then
		return nil
	end

	-- Split by tabs or multiple spaces
	local parts = vim.split(line, "\t+")
	if #parts < 2 then
		-- Try splitting by multiple spaces
		parts = {}
		for part in line:gmatch("%S+") do
			table.insert(parts, part)
		end
	end

	if #parts >= 2 then
		local url_pattern = parts[1]
		local view_path = parts[2]
		local url_name = parts[3] or ""
		local view_name = view_path:match("([^.]+)$") or ""

		return {
			url_pattern = url_pattern,
			view_path = view_path,
			view_name = view_name,
			url_name = url_name,
			urlconf = urlconf_name,
		}
	end

	return nil
end

-- Find the file and line number where a view is defined
local function find_view_definition(view_path)
	-- Convert module path to file path
	local module_parts = vim.split(view_path, ".", { plain = true })
	if #module_parts == 0 then
		return nil, nil
	end

	local view_name = module_parts[#module_parts]
	table.remove(module_parts) -- Remove the view name
	local module_path = table.concat(module_parts, ".")

	-- Try to find the file
	local possible_file = module_path:gsub("%.", "/") .. ".py"

	-- Check if file exists in current working directory
	local cwd = vim.fn.getcwd()
	local file_path = cwd .. "/" .. possible_file

	if vim.fn.filereadable(file_path) == 0 then
		-- Try looking for __init__.py in a module directory
		local module_dir = cwd .. "/" .. module_path:gsub("%.", "/")
		local init_file = module_dir .. "/__init__.py"
		if vim.fn.filereadable(init_file) == 1 then
			file_path = init_file
		else
			return nil, nil
		end
	end

	-- Search for the class or function definition
	local file_handle = io.open(file_path, "r")
	if not file_handle then
		return file_path, nil
	end

	local line_num = 1
	for line in file_handle:lines() do
		-- Look for class or function definition or assignment
		if
			line:match("^class " .. view_name .. "%W")
			or line:match("^def " .. view_name .. "%W")
			or line:match("^" .. view_name .. "%s*=")
		then
			file_handle:close()
			return file_path, line_num
		end
		line_num = line_num + 1
	end

	file_handle:close()
	return file_path, nil
end

-- Fetch URLs from a specific URLconf
local function fetch_urls_from_urlconf(urlconf, urlconf_name, results)
	local cmd = { "python", "manage.py", "show_urls" }
	if urlconf then
		table.insert(cmd, "--urlconf=" .. urlconf)
	end

	-- Run the command
	local output = vim.fn.systemlist(cmd)
	local exit_code = vim.v.shell_error

	if exit_code ~= 0 then
		-- Filter out JSON log messages from stderr
		local has_error = false
		for _, line in ipairs(output) do
			if not line:match("^%s*{") and line:strip() ~= "" then
				has_error = true
				break
			end
		end

		if has_error then
			vim.notify("Warning: Failed to fetch URLs from " .. urlconf_name, vim.log.levels.WARN)
		end
		return
	end

	-- Parse the output
	for _, line in ipairs(output) do
		local entry = parse_url_line(line, urlconf_name)
		if entry then
			table.insert(results, entry)
		end
	end
end

-- Fetch all URLs from all URLconfs
local function fetch_all_urls()
	local results = {}

	-- Define the URLconfs to fetch
	local urlconfs = {
		{ nil, "Default (Lawyers)" },
		{ "PUBLIC_URLCONF", "Public API" },
		{ "CLIENTS_URLCONF", "Clients App" },
	}

	-- Fetch from each URLconf
	for _, urlconf_info in ipairs(urlconfs) do
		local urlconf = urlconf_info[1]
		local name = urlconf_info[2]
		fetch_urls_from_urlconf(urlconf, name, results)
	end

	return results
end

-- Format entry for display
local function format_entry_display(entry)
	-- Format: URL | View Path | URL Name | URLConf
	local url_name_display = entry.url_name ~= "" and entry.url_name or "(unnamed)"
	return string.format("%s | %s | %s | %s", entry.url_pattern, entry.view_path, url_name_display, entry.urlconf)
end

-- Create a previewer that shows the view code
local function create_view_previewer()
	return previewers.new_buffer_previewer({
		title = "View Definition",
		get_buffer_by_name = function(_, entry)
			return "view:" .. entry.value.view_path
		end,
		define_preview = function(self, entry, status)
			local file_path, line_num = find_view_definition(entry.value.view_path)

			if not file_path then
				vim.api.nvim_buf_set_lines(
					self.state.bufnr,
					0,
					-1,
					false,
					{ "Could not locate view definition for: " .. entry.value.view_path }
				)
				return
			end

			-- Read the file
			local lines = vim.fn.readfile(file_path)
			if not lines or #lines == 0 then
				vim.api.nvim_buf_set_lines(
					self.state.bufnr,
					0,
					-1,
					false,
					{ "Could not read file: " .. file_path }
				)
				return
			end

			-- Set the lines in the preview buffer
			vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)

			-- Set filetype for syntax highlighting
			vim.api.nvim_buf_set_option(self.state.bufnr, "filetype", "python")

			-- If we found the line number, highlight it and scroll to it
			if line_num then
				-- Highlight the line
				local ns_id = vim.api.nvim_create_namespace("telescope_view_preview")
				vim.api.nvim_buf_clear_namespace(self.state.bufnr, ns_id, 0, -1)
				vim.api.nvim_buf_add_highlight(self.state.bufnr, ns_id, "Visual", line_num - 1, 0, -1)

				-- Try to scroll to the line
				pcall(vim.api.nvim_win_set_cursor, status.preview_win, { line_num, 0 })
			end
		end,
	})
end

-- Main picker function
function M.leg_url_search()
	-- Check if we're in a directory with manage.py
	if vim.fn.filereadable("manage.py") == 0 then
		vim.notify("manage.py not found in current directory. Are you in a Django project?", vim.log.levels.ERROR)
		return
	end

	vim.notify("Fetching URLs from all URLconfs...", vim.log.levels.INFO)

	-- Fetch all URLs
	local url_entries = fetch_all_urls()

	if #url_entries == 0 then
		vim.notify("No URLs found", vim.log.levels.WARN)
		return
	end

	vim.notify(string.format("Found %d URLs", #url_entries), vim.log.levels.INFO)

	-- Create the picker
	pickers
		.new({}, {
			prompt_title = "Django URL Search",
			finder = finders.new_table({
				results = url_entries,
				entry_maker = function(entry)
					return {
						value = entry,
						display = format_entry_display(entry),
						ordinal = entry.url_pattern
							.. " "
							.. entry.view_path
							.. " "
							.. entry.url_name
							.. " "
							.. entry.urlconf,
					}
				end,
			}),
			sorter = conf.generic_sorter({}),
			previewer = create_view_previewer(),
			attach_mappings = function(prompt_bufnr, _)
				actions.select_default:replace(function()
					actions.close(prompt_bufnr)
					local selection = action_state.get_selected_entry()
					if selection then
						local file_path, line_num = find_view_definition(selection.value.view_path)
						if file_path then
							-- Open the file
							vim.cmd("edit " .. file_path)
							-- Jump to the line if found
							if line_num then
								vim.api.nvim_win_set_cursor(0, { line_num, 0 })
								-- Center the line in the window
								vim.cmd("normal! zz")
							end
						else
							vim.notify(
								"Could not locate view definition for: " .. selection.value.view_path,
								vim.log.levels.WARN
							)
						end
					end
				end)
				return true
			end,
		})
		:find()
end

return M
