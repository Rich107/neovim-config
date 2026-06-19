local M = {}

local builtin = require("telescope.builtin")
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")

-- Directory holding prompt templates. Lives inside the nvim config dir so it is
-- versioned/backed-up alongside the rest of the config and pulls down with it.
local function templates_dir()
	return vim.fs.joinpath(vim.fn.stdpath("config"), "prompts")
end

-- Expand dynamic tokens in template text. Supported:
--   {{date}}            -> today as YYYY-MM-DD
--   {{date:%FORMAT}}    -> today via os.date with a custom strftime format
local function expand_tokens(lines)
	local out = {}
	for _, line in ipairs(lines) do
		line = line:gsub("{{date:([^}]+)}}", function(fmt)
			return os.date(fmt)
		end)
		line = line:gsub("{{date}}", function()
			return os.date("%Y-%m-%d")
		end)
		table.insert(out, line)
	end
	return out
end

-- Replace the contents of the current buffer with the given lines, then drop the
-- cursor on the first {{placeholder}} (if any) so the template is ready to fill.
local function load_into_current_buffer(lines)
	local bufnr = vim.api.nvim_get_current_buf()

	-- We intend to fill this buffer, so make sure it can be written to. The
	-- Ctrl+G temp buffer (and some launch contexts) can arrive read-only.
	vim.api.nvim_set_option_value("modifiable", true, { buf = bufnr })
	vim.api.nvim_set_option_value("readonly", false, { buf = bufnr })

	vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)

	-- Jump to the first {{placeholder}} if present.
	for i, line in ipairs(lines) do
		local col = line:find("{{")
		if col then
			vim.api.nvim_win_set_cursor(0, { i, col - 1 })
			return
		end
	end

	-- No placeholder: park the cursor at the end so you can keep typing.
	vim.api.nvim_win_set_cursor(0, { #lines, 0 })
end

function M.pick_template()
	local dir = templates_dir()

	if vim.fn.isdirectory(dir) == 0 then
		vim.notify("prompt-template: no templates dir at " .. dir, vim.log.levels.WARN)
		return
	end

	builtin.find_files({
		prompt_title = "Prompt Templates",
		cwd = dir,
		-- Include hidden/dotfile templates too, ignore nothing.
		find_command = { "rg", "--files", "--hidden", "--no-ignore", "--glob", "!.git/*" },
		attach_mappings = function(prompt_bufnr, _)
			actions.select_default:replace(function()
				local selection = action_state.get_selected_entry()
				actions.close(prompt_bufnr)
				if not selection then
					return
				end

				local path = vim.fs.joinpath(dir, selection.value)
				local ok, lines = pcall(vim.fn.readfile, path)
				if not ok then
					vim.notify("prompt-template: failed to read " .. path, vim.log.levels.ERROR)
					return
				end

				load_into_current_buffer(expand_tokens(lines))
			end)
			return true
		end,
	})
end

return M
