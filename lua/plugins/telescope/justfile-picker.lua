local M = {}

local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")

-- Function to parse a single just file and extract recipes with metadata
local function parse_just_file(file_path)
	local recipes = {}
	local file = io.open(file_path, "r")
	if not file then
		return recipes
	end

	-- Read all lines into a table for easier parsing
	local lines = {}
	for line in file:lines() do
		table.insert(lines, line)
	end
	file:close()

	local i = 1
	while i <= #lines do
		local line = lines[i]
		local description = ""
		local group = ""
		
		-- Check for description comment (# comment above recipe)
		if i > 1 and lines[i-1]:match("^%s*#%s*(.+)") then
			description = lines[i-1]:match("^%s*#%s*(.+)")
			-- Trim whitespace
			description = description:gsub("^%s*(.-)%s*$", "%1")
		end
		
		-- Check for group attribute [group('name')]
		if i > 1 and lines[i-1]:match("%[group%(['\"](.-)['\"]%)%]") then
			group = lines[i-1]:match("%[group%(['\"](.-)['\"]%)%]")
		end
		-- Also check two lines up for group (in case there's a description between)
		if group == "" and i > 2 and lines[i-2]:match("%[group%(['\"](.-)['\"]%)%]") then
			group = lines[i-2]:match("%[group%(['\"](.-)['\"]%)%]")
		end
		
		-- Match recipe names (lines that start with a non-whitespace character followed by a colon)
		local recipe_name = line:match("^([%w-_]+)%s*%(.*%)%s*:")
		if not recipe_name then
			recipe_name = line:match("^([%w-_]+)%s*:")
		end
		
		if recipe_name and recipe_name ~= "" then
			-- Skip common keywords that might match but aren't recipes
			if not (recipe_name:match("^#") or recipe_name:match("^@")) then
				table.insert(recipes, {
					name = recipe_name,
					description = description,
					group = group
				})
			end
		end
		
		i = i + 1
	end

	return recipes
end

-- Function to format display string with columns
local function format_recipe_display(recipe, file, group, description)
	-- Column widths
	local recipe_width = 20
	local file_width = 15
	local group_width = 15
	
	-- Pad strings to column widths
	local recipe_col = string.format("%-" .. recipe_width .. "s", string.sub(recipe, 1, recipe_width))
	local file_col = string.format("%-" .. file_width .. "s", string.sub(file, 1, file_width))
	local group_col = string.format("%-" .. group_width .. "s", string.sub(group or "-", 1, group_width))
	
	-- Description gets the rest of the space
	local desc_text = description or ""
	
	-- Use vertical bars as separators for better visibility
	return recipe_col .. " │ " .. file_col .. " │ " .. group_col .. " │ " .. desc_text
end

-- Function to find all just files and extract recipes with metadata
local function parse_all_justfiles()
	local all_recipes = {}
	local cwd = vim.fn.getcwd()
	
	-- Check for main Justfile/justfile
	local main_files = {
		cwd .. "/Justfile",
		cwd .. "/justfile"
	}
	
	local main_file = nil
	for _, path in ipairs(main_files) do
		if vim.fn.filereadable(path) == 1 then
			main_file = path
			break
		end
	end
	
	if main_file then
		local recipes = parse_just_file(main_file)
		local filename = vim.fn.fnamemodify(main_file, ":t")
		for _, recipe_info in ipairs(recipes) do
			table.insert(all_recipes, {
				name = recipe_info.name,
				file = filename,
				group = recipe_info.group,
				description = recipe_info.description,
				display = format_recipe_display(
					recipe_info.name,
					filename,
					recipe_info.group,
					recipe_info.description
				)
			})
		end
	end
	
	-- Find and parse all .just files in the current directory
	local just_files = vim.fn.glob(cwd .. "/*.just", false, true)
	for _, file_path in ipairs(just_files) do
		local recipes = parse_just_file(file_path)
		local filename = vim.fn.fnamemodify(file_path, ":t")
		for _, recipe_info in ipairs(recipes) do
			table.insert(all_recipes, {
				name = recipe_info.name,
				file = filename,
				group = recipe_info.group,
				description = recipe_info.description,
				display = format_recipe_display(
					recipe_info.name,
					filename,
					recipe_info.group,
					recipe_info.description
				)
			})
		end
	end
	
	return all_recipes
end

-- Table to store terminal buffer IDs for each recipe
local terminal_buffers = {}

-- Function to run a Just command in Neovim terminal
local function run_in_neovim_terminal(recipe_name)
	local buf_name = "just-" .. recipe_name
	local buf_id = terminal_buffers[buf_name]
	
	-- Check if we already have a terminal buffer for this recipe
	if buf_id and vim.api.nvim_buf_is_valid(buf_id) then
		-- Reuse existing terminal buffer
		-- Find or create a window for the buffer
		local win_id = vim.fn.bufwinid(buf_id)
		if win_id == -1 then
			-- Buffer exists but no window, create a new split
			vim.cmd("split")
			vim.api.nvim_set_current_buf(buf_id)
		else
			-- Window exists, focus it
			vim.api.nvim_set_current_win(win_id)
		end
		
		-- Send interrupt and run the command again
		vim.api.nvim_chan_send(vim.b.terminal_job_id, "\x03")  -- Ctrl-C
		vim.defer_fn(function()
			vim.api.nvim_chan_send(vim.b.terminal_job_id, "clear && just " .. recipe_name .. "\n")
		end, 100)
		
		vim.notify(string.format("Reusing terminal buffer for 'just-%s'", recipe_name), vim.log.levels.INFO)
	else
		-- Create a new terminal buffer
		vim.cmd("split")
		vim.cmd("terminal")
		buf_id = vim.api.nvim_get_current_buf()
		terminal_buffers[buf_name] = buf_id
		
		-- Set buffer name
		vim.api.nvim_buf_set_name(buf_id, buf_name)
		
		-- Send the just command
		vim.defer_fn(function()
			vim.api.nvim_chan_send(vim.b.terminal_job_id, "just " .. recipe_name .. "\n")
		end, 100)
		
		vim.notify(string.format("Created new terminal buffer for 'just-%s'", recipe_name), vim.log.levels.INFO)
	end
	
	-- Enter insert mode to interact with the terminal
	vim.cmd("startinsert")
end

-- Function to run a Just command in tmux or Neovim terminal
local function run_recipe(recipe_name)
	-- Check if we're in a tmux session
	local tmux_session = vim.fn.getenv("TMUX")
	if tmux_session == vim.NIL or tmux_session == "" then
		-- Not in tmux, use Neovim terminal as fallback
		run_in_neovim_terminal(recipe_name)
		return
	end

	-- In tmux, use tmux windows
	local window_name = "just-" .. recipe_name
	
	-- Check if a window with this name already exists in the current session
	local check_window_cmd = string.format("tmux list-windows -F '#{window_name}' | grep -q '^%s$'", window_name)
	vim.fn.system(check_window_cmd)
	local exit_code = vim.v.shell_error
	
	if exit_code == 0 then
		-- Window exists, switch to it and run the command
		local switch_cmd = string.format("tmux select-window -t '%s'", window_name)
		vim.fn.system(switch_cmd)
		
		-- Send the just command to the existing window
		local send_cmd = string.format("tmux send-keys -t '%s' C-c C-u 'just %s' Enter", window_name, recipe_name)
		vim.fn.system(send_cmd)
		
		vim.notify(string.format("Reusing existing tmux window 'just-%s'", recipe_name), vim.log.levels.INFO)
	else
		-- Create a new window with a shell that runs the command and stays open
		local create_cmd = string.format(
			"tmux new-window -n '%s' 'echo \"Running: just %s\"; echo \"===================\"; just %s; echo \"\"; echo \"Command completed. Press Ctrl-C to exit or run more commands.\"; exec bash'",
			window_name, recipe_name, recipe_name
		)
		vim.fn.system(create_cmd)
		
		vim.notify(string.format("Created new tmux window 'just-%s'", recipe_name), vim.log.levels.INFO)
	end
end

-- Main picker function
function M.pick_just_recipe()
	local recipes = parse_all_justfiles()

	if #recipes == 0 then
		vim.notify("No Justfile or .just files found, or no recipes detected in the current directory", vim.log.levels.WARN)
		return
	end

	pickers.new({}, {
		prompt_title = "Just Recipes (Recipe | File | Group | Description)",
		finder = finders.new_table({
			results = recipes,
			entry_maker = function(entry)
				return {
					value = entry,
					display = entry.display,
					ordinal = entry.name .. " " .. (entry.group or "") .. " " .. (entry.description or "") .. " " .. entry.file,
				}
			end,
		}),
		sorter = conf.generic_sorter({}),
		previewer = false,
		attach_mappings = function(prompt_bufnr, _)
			actions.select_default:replace(function()
				actions.close(prompt_bufnr)
				local selection = action_state.get_selected_entry()
				if selection then
					run_recipe(selection.value.name)
				end
			end)
			return true
		end,
	}):find()
end

return M