local M = {}

local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")

-- Function to parse Justfile and extract recipe names
local function parse_justfile()
	local justfile_path = vim.fn.getcwd() .. "/Justfile"
	local alt_justfile_path = vim.fn.getcwd() .. "/justfile"

	-- Check for both Justfile and justfile
	local file_path = nil
	if vim.fn.filereadable(justfile_path) == 1 then
		file_path = justfile_path
	elseif vim.fn.filereadable(alt_justfile_path) == 1 then
		file_path = alt_justfile_path
	else
		return {}
	end

	local recipes = {}
	local file = io.open(file_path, "r")
	if not file then
		return {}
	end

	-- Parse the Justfile for recipe names
	for line in file:lines() do
		-- Match recipe names (lines that start with a non-whitespace character followed by a colon)
		-- This regex matches typical Just recipe definitions
		local recipe_name = line:match("^([%w-_]+)%s*%(.*%)%s*:")
		if not recipe_name then
			recipe_name = line:match("^([%w-_]+)%s*:")
		end
		if recipe_name and recipe_name ~= "" then
			-- Skip common keywords that might match but aren't recipes
			if not (recipe_name:match("^#") or recipe_name:match("^@")) then
				table.insert(recipes, recipe_name)
			end
		end
	end

	file:close()
	return recipes
end

-- Function to run a Just command in a new or existing tmux window
local function run_in_tmux(recipe_name)
	-- Check if we're in a tmux session
	local tmux_session = vim.fn.getenv("TMUX")
	if tmux_session == vim.NIL or tmux_session == "" then
		vim.notify("Not in a tmux session. Please run Neovim inside tmux.", vim.log.levels.ERROR)
		return
	end

	-- Window name with "just-" prefix
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
		
		vim.notify(string.format("Reusing existing window 'just-%s' and running command", recipe_name), vim.log.levels.INFO)
	else
		-- Create a new window with a shell that runs the command and stays open
		local create_cmd = string.format(
			"tmux new-window -n '%s' 'echo \"Running: just %s\"; echo \"===================\"; just %s; echo \"\"; echo \"Command completed. Press Ctrl-C to exit or run more commands.\"; exec bash'",
			window_name, recipe_name, recipe_name
		)
		vim.fn.system(create_cmd)
		
		vim.notify(string.format("Created new window 'just-%s' and running command", recipe_name), vim.log.levels.INFO)
	end
end

-- Main picker function
function M.pick_just_recipe()
	local recipes = parse_justfile()

	if #recipes == 0 then
		vim.notify("No Justfile found or no recipes detected in the current directory", vim.log.levels.WARN)
		return
	end

	pickers.new({}, {
		prompt_title = "Just Recipes",
		finder = finders.new_table({
			results = recipes,
		}),
		sorter = conf.generic_sorter({}),
		attach_mappings = function(prompt_bufnr, _)
			actions.select_default:replace(function()
				actions.close(prompt_bufnr)
				local selection = action_state.get_selected_entry()
				if selection then
					run_in_tmux(selection[1])
				end
			end)
			return true
		end,
	}):find()
end

return M