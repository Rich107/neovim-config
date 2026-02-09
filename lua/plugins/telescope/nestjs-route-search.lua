local M = {}

local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local previewers = require("telescope.previewers")

-- HTTP method decorators to look for
local HTTP_METHODS = {
	"Get",
	"Post",
	"Put",
	"Patch",
	"Delete",
	"Head",
	"Options",
	"All",
}

-- Cache file path
local function get_cache_file_path()
	local cwd = vim.fn.getcwd()
	local cwd_hash = vim.fn.sha256(cwd):sub(1, 16)
	return "/tmp/nvim_nestjs_routes_" .. cwd_hash .. ".json"
end

-- Save routes to cache
local function save_to_cache(route_entries)
	local cache_file = get_cache_file_path()
	local json_str = vim.fn.json_encode(route_entries)
	local file = io.open(cache_file, "w")
	if file then
		file:write(json_str)
		file:close()
		return true
	end
	return false
end

-- Load routes from cache
local function load_from_cache()
	local cache_file = get_cache_file_path()
	if vim.fn.filereadable(cache_file) == 0 then
		return nil
	end

	local file = io.open(cache_file, "r")
	if not file then
		return nil
	end

	local content = file:read("*all")
	file:close()

	local success, route_entries = pcall(vim.fn.json_decode, content)
	if success and route_entries then
		return route_entries
	end

	return nil
end

-- Find all controller files in the project
local function find_controller_files()
	local controller_files = {}

	-- Use ripgrep to find controller files efficiently
	local rg_cmd = { "rg", "--files", "-g", "*.controller.ts", "-g", "*.controller.js" }
	local output = vim.fn.systemlist(rg_cmd)

	if vim.v.shell_error == 0 then
		for _, file in ipairs(output) do
			if vim.trim(file) ~= "" then
				table.insert(controller_files, file)
			end
		end
	end

	-- Also search for files with @Controller decorator if rg didn't find controller files
	if #controller_files == 0 then
		local grep_cmd = { "rg", "-l", "@Controller", "-g", "*.ts", "-g", "*.js" }
		output = vim.fn.systemlist(grep_cmd)

		if vim.v.shell_error == 0 then
			for _, file in ipairs(output) do
				if vim.trim(file) ~= "" then
					table.insert(controller_files, file)
				end
			end
		end
	end

	return controller_files
end

-- Extract controller base path from @Controller decorator
local function extract_controller_path(lines)
	for _, line in ipairs(lines) do
		-- Match @Controller('path') or @Controller("path") or @Controller()
		local path = line:match("@Controller%s*%(%s*['\"]([^'\"]*)['\"]%s*%)")
		if path then
			return path
		end
		-- Check for empty @Controller()
		if line:match("@Controller%s*%(%)") or line:match("@Controller%s*$") then
			return ""
		end
		-- Match @Controller({ path: 'path' })
		path = line:match("@Controller%s*%(%s*{[^}]*path%s*:%s*['\"]([^'\"]*)['\"]")
		if path then
			return path
		end
	end
	return nil
end

-- Extract routes from a controller file
local function extract_routes_from_file(file_path)
	local routes = {}

	local lines = vim.fn.readfile(file_path)
	if not lines or #lines == 0 then
		return routes
	end

	-- Find controller base path
	local controller_path = extract_controller_path(lines) or ""

	-- Build regex pattern for HTTP method decorators
	local method_pattern = "@(" .. table.concat(HTTP_METHODS, "|") .. ")%s*%("

	-- Track pending decorator info
	local pending_method = nil
	local pending_path = nil
	local pending_line = nil

	for line_num, line in ipairs(lines) do
		-- Check for HTTP method decorators
		for _, method in ipairs(HTTP_METHODS) do
			-- Pattern: @Get(), @Get('path'), @Get("path"), @Get(':id')
			local decorator_pattern = "@" .. method .. "%s*%("

			if line:match(decorator_pattern) then
				-- Extract the path from the decorator
				local route_path = line:match("@" .. method .. "%s*%(%s*['\"]([^'\"]*)['\"]%s*%)")

				-- Handle empty decorator like @Get()
				if not route_path and line:match("@" .. method .. "%s*%(%)") then
					route_path = ""
				end

				-- Handle decorator with options object like @Get({ path: '/foo' })
				if not route_path then
					route_path = line:match("@" .. method .. "%s*%(%s*{[^}]*path%s*:%s*['\"]([^'\"]*)['\"]")
				end

				-- Default to empty string if we found the decorator but couldn't extract path
				if not route_path and line:match("@" .. method) then
					route_path = ""
				end

				if route_path ~= nil then
					pending_method = method:upper()
					pending_path = route_path
					pending_line = line_num
				end
			end
		end

		-- Look for the method definition following a decorator
		if pending_method then
			-- Match async methodName( or methodName(
			local method_name = line:match("^%s*async%s+([%w_]+)%s*%(")
			if not method_name then
				method_name = line:match("^%s*([%w_]+)%s*%(")
			end
			-- Also match public/private/protected methods
			if not method_name then
				method_name = line:match("^%s*[public|private|protected]?%s*async%s+([%w_]+)%s*%(")
			end
			if not method_name then
				method_name = line:match("^%s*[public|private|protected]%s+([%w_]+)%s*%(")
			end

			if method_name and not method_name:match("^@") then
				-- Build the full path
				local full_path = "/" .. controller_path
				if pending_path and pending_path ~= "" then
					if pending_path:sub(1, 1) == "/" then
						full_path = full_path .. pending_path
					else
						full_path = full_path .. "/" .. pending_path
					end
				end

				-- Normalize path (remove double slashes, ensure leading slash)
				full_path = full_path:gsub("//+", "/")
				if full_path == "" then
					full_path = "/"
				end

				table.insert(routes, {
					path = full_path,
					method = pending_method,
					handler = method_name,
					file_path = file_path,
					line_num = line_num,
					controller_path = controller_path,
				})

				pending_method = nil
				pending_path = nil
				pending_line = nil
			end
		end
	end

	return routes
end

-- Fetch all routes from all controllers
local function fetch_all_routes()
	local all_routes = {}

	local controller_files = find_controller_files()

	if #controller_files == 0 then
		vim.notify("No NestJS controller files found", vim.log.levels.WARN)
		return all_routes
	end

	for _, file_path in ipairs(controller_files) do
		local routes = extract_routes_from_file(file_path)
		for _, route in ipairs(routes) do
			table.insert(all_routes, route)
		end
	end

	-- Sort routes by path
	table.sort(all_routes, function(a, b)
		if a.path == b.path then
			return a.method < b.method
		end
		return a.path < b.path
	end)

	return all_routes
end

-- Format entry for display
local function format_entry_display(entry)
	local method_display = string.format("%-8s", "[" .. entry.method .. "]")
	local path_display = string.format("%-50s", entry.path)
	local handler_display = entry.handler
	return method_display .. " " .. path_display .. " → " .. handler_display
end

-- Create a previewer that shows the handler code
local function create_handler_previewer()
	return previewers.new_buffer_previewer({
		title = "Controller Handler",
		get_buffer_by_name = function(_, entry)
			return "handler:" .. entry.value.file_path .. ":" .. entry.value.handler
		end,
		define_preview = function(self, entry, status)
			local file_path = entry.value.file_path
			local line_num = entry.value.line_num

			if not file_path or file_path == "" then
				vim.api.nvim_buf_set_lines(
					self.state.bufnr,
					0,
					-1,
					false,
					{ "Could not locate handler definition for: " .. entry.value.handler }
				)
				return
			end

			-- Read the file
			local lines = vim.fn.readfile(file_path)
			if not lines or #lines == 0 then
				vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, { "Could not read file: " .. file_path })
				return
			end

			-- Set the lines in the preview buffer
			vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)

			-- Set filetype for syntax highlighting
			local filetype = "typescript"
			if file_path:match("%.js$") then
				filetype = "javascript"
			end
			vim.api.nvim_buf_set_option(self.state.bufnr, "filetype", filetype)

			-- If we have a line number, highlight it and scroll to it
			if line_num then
				local ns_id = vim.api.nvim_create_namespace("telescope_nestjs_preview")
				vim.api.nvim_buf_clear_namespace(self.state.bufnr, ns_id, 0, -1)

				-- Highlight the decorator line (one above the method) and the method line
				if line_num > 1 then
					-- Find the decorator line(s) above
					local decorator_start = line_num - 1
					for i = line_num - 1, math.max(1, line_num - 5), -1 do
						local check_line = lines[i]
						if check_line and check_line:match("@%w+") then
							decorator_start = i
						else
							break
						end
					end
					for i = decorator_start, line_num do
						vim.api.nvim_buf_add_highlight(self.state.bufnr, ns_id, "Visual", i - 1, 0, -1)
					end
				else
					vim.api.nvim_buf_add_highlight(self.state.bufnr, ns_id, "Visual", line_num - 1, 0, -1)
				end

				-- Scroll to show a bit of context above
				local scroll_line = math.max(1, line_num - 3)
				pcall(vim.api.nvim_win_set_cursor, status.preview_win, { scroll_line, 0 })
			end
		end,
	})
end

-- Main picker function
function M.nestjs_route_search(opts)
	opts = opts or {}

	-- Try to load from cache first unless force refresh
	local route_entries = nil
	if not opts.force_refresh then
		route_entries = load_from_cache()
	end

	if route_entries then
		vim.notify(string.format("Loaded %d routes from cache", #route_entries), vim.log.levels.INFO)
	else
		-- Cache miss - fetch routes
		vim.notify("Scanning for NestJS routes...", vim.log.levels.INFO)

		route_entries = fetch_all_routes()

		if #route_entries == 0 then
			vim.notify("No routes found. Is this a NestJS project?", vim.log.levels.WARN)
			return
		end

		-- Save to cache
		if save_to_cache(route_entries) then
			vim.notify(string.format("Found and cached %d routes", #route_entries), vim.log.levels.INFO)
		else
			vim.notify(string.format("Found %d routes (cache save failed)", #route_entries), vim.log.levels.WARN)
		end
	end

	-- Create the picker
	pickers
		.new({}, {
			prompt_title = "NestJS Route Search",
			finder = finders.new_table({
				results = route_entries,
				entry_maker = function(entry)
					return {
						value = entry,
						display = format_entry_display(entry),
						ordinal = entry.path .. " " .. entry.method .. " " .. entry.handler,
					}
				end,
			}),
			sorter = conf.generic_sorter({}),
			previewer = create_handler_previewer(),
			attach_mappings = function(prompt_bufnr, _)
				actions.select_default:replace(function()
					actions.close(prompt_bufnr)
					local selection = action_state.get_selected_entry()
					if selection then
						local file_path = selection.value.file_path
						local line_num = selection.value.line_num

						if file_path and file_path ~= "" then
							-- Open the file
							vim.cmd("edit " .. file_path)

							-- Jump to the line if found
							if line_num then
								vim.api.nvim_win_set_cursor(0, { line_num, 0 })
								vim.cmd("normal! zz")
							end
						else
							vim.notify(
								"Could not locate handler definition for: " .. selection.value.handler,
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

-- Clear cache function
function M.clear_cache()
	local cache_file = get_cache_file_path()
	if vim.fn.filereadable(cache_file) == 1 then
		vim.fn.delete(cache_file)
		vim.notify("NestJS route cache cleared", vim.log.levels.INFO)
	else
		vim.notify("No cache file found", vim.log.levels.INFO)
	end
end

return M
