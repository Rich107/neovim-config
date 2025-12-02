local M = {}

local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")

-- Function to parse just --list output
local function parse_just_list()
	local recipes = {}
	
	-- Run just --list with custom formatting for cleaner parsing
	local cmd = "just --list --unsorted --list-heading '' --list-prefix '' 2>/dev/null"
	local output = vim.fn.system(cmd)
	
	-- Check if just command succeeded
	if vim.v.shell_error ~= 0 then
		return recipes
	end
	
	-- Parse the output line by line
	for line in output:gmatch("[^\r\n]+") do
		-- Skip empty lines
		if line:match("^%s*$") then
			goto continue
		end
		
		-- Parse recipe line
		-- Format is typically: "recipe-name      # Description"
		-- or just: "recipe-name"
		local recipe_name, description = line:match("^([%w-_]+)%s+#%s*(.+)")
		if not recipe_name then
			-- Try without description - match recipe names with alphanumeric, dash, underscore
			recipe_name = line:match("^([%w-_]+)")
		end
		
		if recipe_name then
			-- Clean up recipe name (remove trailing spaces)
			recipe_name = recipe_name:gsub("%s+$", "")
			
			table.insert(recipes, {
				name = recipe_name,
				description = description or ""
			})
		end
		
		::continue::
	end
	
	return recipes
end

-- Function to format display string with columns
local function format_recipe_display(recipe, description)
	-- Column widths
	local recipe_width = 30
	
	-- Pad recipe name to column width
	local recipe_col = string.format("%-" .. recipe_width .. "s", string.sub(recipe, 1, recipe_width))
	
	-- Description gets the rest of the space
	local desc_text = description or ""
	
	-- Use vertical bar as separator for better visibility
	if desc_text ~= "" then
		return recipe_col .. " │ " .. desc_text
	else
		return recipe_col
	end
end

-- Function to get all recipes using just command
local function get_all_recipes()
	local all_recipes = {}
	
	-- First try to get recipes from main justfile
	local main_recipes = parse_just_list()
	
	for _, recipe_info in ipairs(main_recipes) do
		table.insert(all_recipes, {
			name = recipe_info.name,
			description = recipe_info.description,
			display = format_recipe_display(
				recipe_info.name,
				recipe_info.description
			)
		})
	end
	
	-- Also check for .just files and try to parse them
	local cwd = vim.fn.getcwd()
	local just_files = vim.fn.glob(cwd .. "/*.just", false, true)
	
	for _, file_path in ipairs(just_files) do
		local filename = vim.fn.fnamemodify(file_path, ":t:r") -- Get filename without extension
		-- Try to list recipes from the specific just file
		local cmd = string.format("just --justfile %s --list --unsorted --list-heading '' --list-prefix '' 2>/dev/null", file_path)
		local output = vim.fn.system(cmd)
		
		if vim.v.shell_error == 0 and output ~= "" then
			for line in output:gmatch("[^\r\n]+") do
				if not line:match("^%s*$") then
					local recipe_name, description = line:match("^([%w-_]+)%s+#%s*(.+)")
					if not recipe_name then
						recipe_name = line:match("^([%w-_]+)")
					end
					
					if recipe_name then
						recipe_name = recipe_name:gsub("%s+$", "")
						-- Add file prefix to distinguish from main justfile
						local prefixed_name = filename .. "::" .. recipe_name
						table.insert(all_recipes, {
							name = prefixed_name,
							description = description or "",
							display = format_recipe_display(
								prefixed_name .. " (" .. filename .. ".just)",
								description or ""
							)
						})
					end
				end
			end
		end
	end
	
	return all_recipes
end

-- Table to store terminal buffer IDs for each recipe
local terminal_buffers = {}

-- Function to detect the best available shell (prioritizing zsh)
local function get_preferred_shell()
	-- First, check if zsh is available
	local zsh_check = vim.fn.system("which zsh 2>/dev/null")
	if vim.v.shell_error == 0 and zsh_check ~= "" then
		return "zsh"
	end
	
	-- Fall back to $SHELL environment variable
	local shell_env = vim.fn.getenv("SHELL")
	if shell_env ~= vim.NIL and shell_env ~= "" then
		return shell_env
	end
	
	-- Final fallback to bash
	return "bash"
end

-- Function to run a Just command in Neovim terminal with custom command
local function run_in_neovim_terminal_with_cmd(display_name, just_cmd, recipe_name)
	local buf_name = "just-" .. display_name
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
			vim.api.nvim_chan_send(vim.b.terminal_job_id, string.format("clear && %s %s\n", just_cmd, recipe_name))
		end, 100)
		
		vim.notify(string.format("Reusing terminal buffer for 'just-%s'", display_name), vim.log.levels.INFO)
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
			vim.api.nvim_chan_send(vim.b.terminal_job_id, string.format("%s %s\n", just_cmd, recipe_name))
		end, 100)
		
		vim.notify(string.format("Created new terminal buffer for 'just-%s'", display_name), vim.log.levels.INFO)
	end
	
	-- Enter insert mode to interact with the terminal
	vim.cmd("startinsert")
end

-- Function to run a Just command in tmux or Neovim terminal
local function run_recipe(recipe_name)
	-- Parse recipe name to check if it has a file prefix (for .just files)
	local just_cmd = "just"
	local display_name = recipe_name
	local actual_recipe = recipe_name
	
	if recipe_name:match("::") then
		-- This is from a .just file with format "filename::recipe"
		local file, recipe = recipe_name:match("^(.+)::(.+)$")
		just_cmd = string.format("just --justfile %s.just", file)
		actual_recipe = recipe
		display_name = recipe_name:gsub("::", "-")
	end
	
	-- Check if we're in a tmux session
	local tmux_session = vim.fn.getenv("TMUX")
	if tmux_session == vim.NIL or tmux_session == "" then
		-- Not in tmux, use Neovim terminal as fallback
		run_in_neovim_terminal_with_cmd(display_name, just_cmd, actual_recipe)
		return
	end

	-- In tmux, use tmux windows
	local window_name = "just-" .. display_name
	
	-- Check if a window with this name already exists in the current session
	local check_window_cmd = string.format("tmux list-windows -F '#{window_name}' | grep -q '^%s$'", window_name)
	vim.fn.system(check_window_cmd)
	local exit_code = vim.v.shell_error
	
	if exit_code == 0 then
		-- Window exists, switch to it and run the command
		local switch_cmd = string.format("tmux select-window -t '%s'", window_name)
		vim.fn.system(switch_cmd)
		
		-- Send the just command to the existing window
		local send_cmd = string.format("tmux send-keys -t '%s' C-c C-u '%s %s' Enter", window_name, just_cmd, actual_recipe)
		vim.fn.system(send_cmd)
		
		vim.notify(string.format("Reusing existing tmux window 'just-%s'", display_name), vim.log.levels.INFO)
	else
		-- Create a new window with a shell that runs the command and stays open
		local preferred_shell = get_preferred_shell()
		local create_cmd = string.format(
			"tmux new-window -n '%s' 'echo \"Running: %s %s\"; echo \"===================\"; %s %s; echo \"\"; echo \"Command completed. Press Ctrl-C to exit or run more commands.\"; exec %s'",
			window_name, just_cmd, actual_recipe, just_cmd, actual_recipe, preferred_shell
		)
		vim.fn.system(create_cmd)
		
		vim.notify(string.format("Created new tmux window 'just-%s'", display_name), vim.log.levels.INFO)
	end
end

-- Main picker function
function M.pick_just_recipe()
	local recipes = get_all_recipes()

	if #recipes == 0 then
		vim.notify("No recipes found. Make sure 'just' is installed and a Justfile exists.", vim.log.levels.WARN)
		return
	end

	pickers.new({}, {
		prompt_title = "Just Recipes",
		finder = finders.new_table({
			results = recipes,
			entry_maker = function(entry)
				return {
					value = entry,
					display = entry.display,
					ordinal = entry.name .. " " .. (entry.description or ""),
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