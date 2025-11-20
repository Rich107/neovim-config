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

-- Function to run a Just command in a new tmux window
local function run_in_tmux(recipe_name)
	-- Check if we're in a tmux session
	local tmux_session = vim.fn.getenv("TMUX")
	if tmux_session == vim.NIL or tmux_session == "" then
		vim.notify("Not in a tmux session. Please run Neovim inside tmux.", vim.log.levels.ERROR)
		return
	end

	-- Create a new tmux window with the recipe name and run the just command
	local cmd = string.format("tmux new-window -n '%s' 'just %s; read -p \"Press enter to close...\"'", recipe_name, recipe_name)
	vim.fn.system(cmd)

	-- Notify the user
	vim.notify(string.format("Running 'just %s' in new tmux window", recipe_name), vim.log.levels.INFO)
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