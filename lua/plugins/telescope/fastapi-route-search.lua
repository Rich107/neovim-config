local M = {}

local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local previewers = require("telescope.previewers")

-- Python script to extract routes (embedded)
local EXTRACTOR_SCRIPT = [[
#!/usr/bin/env python3
import sys
import os
import inspect

# Add current directory to Python path
sys.path.insert(0, os.getcwd())

def extract_routes(app_import_path):
    try:
        if ':' in app_import_path:
            module_path, app_var = app_import_path.split(':', 1)
        else:
            module_path = app_import_path
            app_var = 'app'
        
        module = __import__(module_path, fromlist=[app_var])
        app = getattr(module, app_var)
        
        routes_found = []
        
        for route in app.routes:
            if hasattr(route, 'path') and hasattr(route, 'endpoint'):
                path = route.path
                
                if hasattr(route, 'methods'):
                    methods = ','.join(sorted(route.methods))
                else:
                    methods = 'GET'
                
                endpoint = route.endpoint
                
                if endpoint is None or not callable(endpoint):
                    continue
                
                module_name = endpoint.__module__ if hasattr(endpoint, '__module__') else ''
                func_name = endpoint.__name__ if hasattr(endpoint, '__name__') else ''
                endpoint_path = f"{module_name}.{func_name}" if module_name else func_name
                
                file_path = ''
                line_num = ''
                try:
                    file_path = inspect.getfile(endpoint)
                    source_lines, start_line = inspect.getsourcelines(endpoint)
                    line_num = str(start_line)
                except (TypeError, OSError):
                    pass
                
                route_name = ''
                if hasattr(route, 'name'):
                    route_name = route.name or ''
                
                routes_found.append({
                    'path': path,
                    'methods': methods,
                    'endpoint_path': endpoint_path,
                    'file_path': file_path,
                    'line_num': line_num,
                    'route_name': route_name
                })
        
        for route in routes_found:
            print(f"{route['path']}\t{route['methods']}\t{route['endpoint_path']}\t{route['file_path']}\t{route['line_num']}\t{route['route_name']}")
        
        return True
        
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        import traceback
        traceback.print_exc(file=sys.stderr)
        return False

if __name__ == '__main__':
    if len(sys.argv) < 2:
        common_patterns = ['main:app', 'app.main:app', 'src.main:app', 'api.main:app']
        
        for pattern in common_patterns:
            try:
                if extract_routes(pattern):
                    sys.exit(0)
            except:
                continue
        
        print("Error: Could not find FastAPI app.", file=sys.stderr)
        sys.exit(1)
    else:
        app_path = sys.argv[1]
        if extract_routes(app_path):
            sys.exit(0)
        else:
            sys.exit(1)
]]

-- Cache file path
local function get_cache_file_path()
	local cwd = vim.fn.getcwd()
	local cwd_hash = vim.fn.sha256(cwd):sub(1, 16)
	return "/tmp/nvim_fastapi_routes_" .. cwd_hash .. ".json"
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

-- Parse a line from the extractor output
local function parse_route_line(line)
	local parts = vim.split(line, "\t")
	if #parts < 5 then
		return nil
	end

	return {
		path = parts[1],
		methods = parts[2],
		endpoint_path = parts[3],
		file_path = parts[4],
		line_num = tonumber(parts[5]) or nil,
		route_name = parts[6] or "",
	}
end

-- Find FastAPI app location by checking common patterns
local function find_app_location()
	local common_patterns = {
		{ file = "main.py", module = "main" },
		{ file = "app/main.py", module = "app.main" },
		{ file = "src/main.py", module = "src.main" },
		{ file = "api/main.py", module = "api.main" },
		{ file = "app.py", module = "app" },
		{ file = "application.py", module = "application" },
	}

	for _, pattern in ipairs(common_patterns) do
		local file = pattern.file
		local module = pattern.module
		
		if vim.fn.filereadable(file) == 1 then
			-- Try to detect the app variable in the file
			local content = vim.fn.readfile(file)
			for _, line in ipairs(content) do
				-- Look for FastAPI app instantiation with various patterns
				local var_name = nil
				
				-- Pattern: app = FastAPI()
				var_name = line:match("^(%w+)%s*=%s*FastAPI%s*%(")
				if not var_name then
					-- Pattern: app: FastAPI = FastAPI()
					var_name = line:match("^(%w+)%s*:%s*FastAPI%s*=%s*FastAPI%s*%(")
				end
				if not var_name then
					-- Pattern: app = create_app() or similar factory
					if line:match("FastAPI") then
						var_name = line:match("^(%w+)%s*=")
					end
				end
				
				if var_name then
					return module .. ":" .. var_name
				end
			end
			
			-- If we found the file but no explicit instantiation, try default "app"
			for _, line in ipairs(content) do
				if line:match("FastAPI") then
					return module .. ":app"
				end
			end
		end
	end

	return nil
end

-- Fetch all routes from FastAPI app
local function fetch_all_routes(app_location)
	-- Create a temporary file with the extractor script
	local tmp_script = "/tmp/nvim_fastapi_extractor.py"
	local file = io.open(tmp_script, "w")
	if not file then
		vim.notify("Failed to create temporary extractor script", vim.log.levels.ERROR)
		return {}
	end
	file:write(EXTRACTOR_SCRIPT)
	file:close()

	-- Run the script
	local cmd = { "python3", tmp_script }
	if app_location then
		table.insert(cmd, app_location)
	end

	local output = vim.fn.systemlist(cmd)
	local exit_code = vim.v.shell_error

	-- Clean up temp file
	vim.fn.delete(tmp_script)

	if exit_code ~= 0 then
		-- Show the actual error messages
		local error_msg = "Failed to extract FastAPI routes:\n"
		for _, line in ipairs(output) do
			if vim.trim(line) ~= "" then
				error_msg = error_msg .. line .. "\n"
			end
		end
		vim.notify(error_msg, vim.log.levels.ERROR)
		
		-- Also print to help debug
		print("=== FastAPI Route Extraction Error ===")
		print("Command:", vim.inspect(cmd))
		print("Exit code:", exit_code)
		print("Output:")
		for _, line in ipairs(output) do
			print(line)
		end
		print("=====================================")
		
		return {}
	end

	-- Parse the output
	local results = {}
	for _, line in ipairs(output) do
		local entry = parse_route_line(line)
		if entry then
			table.insert(results, entry)
		end
	end

	return results
end

-- Format entry for display
local function format_entry_display(entry)
	local methods_display = string.format("%-20s", "[" .. entry.methods .. "]")
	local path_display = string.format("%-50s", entry.path)
	local endpoint_display = entry.endpoint_path
	return methods_display .. " " .. path_display .. " → " .. endpoint_display
end

-- Create a previewer that shows the endpoint code
local function create_endpoint_previewer()
	return previewers.new_buffer_previewer({
		title = "Endpoint Definition",
		get_buffer_by_name = function(_, entry)
			return "endpoint:" .. entry.value.endpoint_path
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
					{ "Could not locate endpoint definition for: " .. entry.value.endpoint_path }
				)
				return
			end

			-- Make file path relative if it's absolute
			if file_path:sub(1, 1) == "/" then
				local cwd = vim.fn.getcwd()
				if file_path:sub(1, #cwd) == cwd then
					file_path = file_path:sub(#cwd + 2) -- +2 to skip the slash
				end
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

			-- If we have a line number, highlight it and scroll to it
			if line_num then
				local ns_id = vim.api.nvim_create_namespace("telescope_endpoint_preview")
				vim.api.nvim_buf_clear_namespace(self.state.bufnr, ns_id, 0, -1)
				vim.api.nvim_buf_add_highlight(self.state.bufnr, ns_id, "Visual", line_num - 1, 0, -1)

				pcall(vim.api.nvim_win_set_cursor, status.preview_win, { line_num, 0 })
			end
		end,
	})
end

-- Main picker function
function M.fastapi_route_search(opts)
	opts = opts or {}

	-- Try to load from cache first
	local route_entries = load_from_cache()

	if route_entries then
		vim.notify(string.format("Loaded %d routes from cache", #route_entries), vim.log.levels.INFO)
	else
		-- Cache miss - fetch routes
		-- Try to find app location
		local app_location = opts.app_location or find_app_location()
		
		if app_location then
			vim.notify("Extracting routes from FastAPI app (" .. app_location .. ")...", vim.log.levels.INFO)
		else
			vim.notify("Extracting routes from FastAPI app (auto-detecting)...", vim.log.levels.INFO)
		end

		route_entries = fetch_all_routes(app_location)

		if #route_entries == 0 then
			vim.notify("No routes found. Is this a FastAPI project?", vim.log.levels.WARN)
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
			prompt_title = "FastAPI Route Search",
			finder = finders.new_table({
				results = route_entries,
				entry_maker = function(entry)
					return {
						value = entry,
						display = format_entry_display(entry),
						ordinal = entry.path .. " " .. entry.methods .. " " .. entry.endpoint_path,
					}
				end,
			}),
			sorter = conf.generic_sorter({}),
			previewer = create_endpoint_previewer(),
			attach_mappings = function(prompt_bufnr, _)
				actions.select_default:replace(function()
					actions.close(prompt_bufnr)
					local selection = action_state.get_selected_entry()
					if selection then
						local file_path = selection.value.file_path
						local line_num = selection.value.line_num

						if file_path and file_path ~= "" then
							-- Make file path relative if needed
							if file_path:sub(1, 1) == "/" then
								local cwd = vim.fn.getcwd()
								if file_path:sub(1, #cwd) == cwd then
									file_path = file_path:sub(#cwd + 2)
								end
							end

							-- Open the file
							vim.cmd("edit " .. file_path)

							-- Jump to the line if found
							if line_num then
								vim.api.nvim_win_set_cursor(0, { line_num, 0 })
								vim.cmd("normal! zz")
							end
						else
							vim.notify(
								"Could not locate endpoint definition for: " .. selection.value.endpoint_path,
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
		vim.notify("FastAPI route cache cleared", vim.log.levels.INFO)
	else
		vim.notify("No cache file found", vim.log.levels.INFO)
	end
end

return M
