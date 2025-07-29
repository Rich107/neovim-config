return {
	{
		"nvim-telescope/telescope-ui-select.nvim",
	},
	{
		"nvim-telescope/telescope.nvim",
		tag = "0.1.5",
		dependencies = {
			"nvim-lua/plenary.nvim",
			{ "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
			"nvim-tree/nvim-web-devicons",
			"folke/todo-comments.nvim",
		},
		config = function()
			require("telescope").setup({
				defaults = {
					layout_strategy = "vertical",
					layout_config = { height = 0.95, width = 0.95 },
					prompt_prefix = "🔭 ", -- Adding the emoji as the prompt prefix
					file_ignore_patterns = {
						"node_modules",
						"lib",
						".git/",
						-- ".git/*",
					},
					-- Customizing path display to show only the filename and first two parent folders
					path_display = function(opts, path)
						local tail = require("telescope.utils").path_tail(path)
						local dirs = vim.split(vim.fn.fnamemodify(path, ":.:h"), "/")
						local parent_dirs = ""
						if #dirs > 1 then
							parent_dirs = table.concat(dirs, "/", math.max(#dirs - 1, #dirs - 2))
						else
							parent_dirs = dirs[1] or ""
						end
						return parent_dirs .. "/" .. tail
					end,
				},
				extensions = {
					["ui-select"] = {
						require("telescope.themes").get_dropdown({}),
					},
				},
			})

			local builtin = require("telescope.builtin")
			local keymap = vim.keymap
			-- keymap.set("n", "<leader>tw", function()
			-- 	require("telescope.builtin").find_files({ "--hidden" })
			-- end, { desc = "Fuzzy find files + failing to find hidden files" })
			keymap.set("n", "<leader>tf", function()
				require("telescope.builtin").find_files({
					find_command = { "rg", "--ignore", "--hidden", "--files" },
					prompt_prefix = "🔭 ",
				})
			end, { desc = "Fuzzy find files + hidden files" })

			keymap.set("n", "<leader>ss", function()
				require("telescope.builtin").spell_suggest({
					sorting_strategy = "ascending",
					layout_strategy = "horizontal",
					layout_config = {
						prompt_position = "top", -- Places the prompt at the top
						width = 0.8, -- Optional: Adjust the width of the finder
						height = 0.5, -- Optional: Adjust the height of the finder
					},
				})
			end, { desc = "spell suggest" })

			keymap.set("n", "<leader>to", function()
				builtin.oldfiles({ cwd_only = true })
			end, { desc = "Fuzzy search recent files in CWD" })
			keymap.set("n", "<leader>tr", builtin.resume, { desc = "Go back to last search" })
			keymap.set("n", "<leader>ts", builtin.live_grep, { desc = "Find string in cwd" })
			keymap.set({ "n", "v" }, "<leader>tv", builtin.grep_string, { desc = "Find selected string in cwd" })
			-- keymap.set("n", "<leader>tc", builtin.commands, { desc = "Find string under cursor in cwd" })
			keymap.set("n", "<leader>tt", "<cmd>TodoTelescope<cr>", { desc = "Find todos" })
			-- keymap.set("n", "<leader>th", builtin.help_tags, { desc = "Help Search" })
			keymap.set("n", "<leader>tj", builtin.jumplist, { desc = "Search though jumplist history" })
			keymap.set("n", "<leader>tl", function()
				local harpoon = require("harpoon")
				local conf = require("telescope.config").values
				local file_paths = {}
				for _, item in ipairs(harpoon:list().items) do
					table.insert(file_paths, item.value)
				end

				require("telescope.pickers")
					.new({}, {
						prompt_title = "Harpoon",
						finder = require("telescope.finders").new_table({
							results = file_paths,
						}),
						previewer = conf.file_previewer({}),
						sorter = conf.generic_sorter({}),
					})
					:find()
			end, { desc = "Search Harpoon marks" })
			keymap.set("n", "<leader>tk", builtin.keymaps, { desc = "Search though keymaps" })
			keymap.set("n", "<leader>ty", builtin.registers, { desc = "Search though registers" })
			vim.api.nvim_set_keymap(
				"n",
				"<leader>tc",
				'<cmd>lua require("telescope.builtin").git_commits({ previewer = delta })<CR>',
				{ noremap = true, silent = true }
			)

			-- Git file history picker
			keymap.set("n", "<leader>th", function()
				local current_file = vim.fn.expand("%:p")
				if current_file == "" then
					vim.notify("No file is currently open", vim.log.levels.WARN)
					return
				end

				local relative_file = vim.fn.fnamemodify(current_file, ":.")
				local pickers = require("telescope.pickers")
				local finders = require("telescope.finders")
				local conf = require("telescope.config").values
				local actions = require("telescope.actions")
				local action_state = require("telescope.actions.state")
				local previewers = require("telescope.previewers")

				-- Get git log for the current file
				local cmd = string.format(
					"git log --pretty=format:'%%h|%%ad|%%an|%%s' --date=short --follow -- %s",
					vim.fn.shellescape(relative_file)
				)

				local results = {}
				local handle = io.popen(cmd)
				if handle then
					for line in handle:lines() do
						local hash, date, author, message = line:match("([^|]+)|([^|]+)|([^|]+)|(.+)")
						if hash then
							table.insert(results, {
								hash = hash,
								date = date,
								author = author,
								message = message,
								display = string.format("%-8s %s %-15s %s", hash, date, author, message),
							})
						end
					end
					handle:close()
				end

				if #results == 0 then
					vim.notify("No git history found for " .. relative_file, vim.log.levels.WARN)
					return
				end

				pickers
					.new({}, {
						prompt_title = "Git File History: " .. vim.fn.fnamemodify(relative_file, ":t"),
						finder = finders.new_table({
							results = results,
							entry_maker = function(entry)
								return {
									value = entry,
									display = entry.display,
									ordinal = entry.hash
										.. " "
										.. entry.date
										.. " "
										.. entry.author
										.. " "
										.. entry.message,
								}
							end,
						}),
						sorter = conf.generic_sorter({}),
						previewer = previewers.new_buffer_previewer({
							title = "Changes in Commit",
							get_buffer_by_name = function(_, entry)
								return "diff:" .. entry.value.hash .. ":" .. relative_file
							end,
							define_preview = function(self, entry, status)
								-- Get the diff for this specific commit and file
								local cmd_diff = string.format(
									"git show --no-merges --format= --unified=3 %s -- %s",
									entry.value.hash,
									vim.fn.shellescape(relative_file)
								)
								
								local handle_diff = io.popen(cmd_diff)
								if handle_diff then
									local diff_content = handle_diff:read("*all")
									handle_diff:close()
									
									if diff_content and diff_content ~= "" then
										-- Process the diff to make it more readable
										local lines = vim.split(diff_content, "\n")
										local processed_lines = {}
										
										-- Add commit info header
										table.insert(processed_lines, "Commit: " .. entry.value.hash)
										table.insert(processed_lines, "Date: " .. entry.value.date)
										table.insert(processed_lines, "Author: " .. entry.value.author)
										table.insert(processed_lines, "Message: " .. entry.value.message)
										table.insert(processed_lines, "")
										table.insert(processed_lines, "Changes to " .. vim.fn.fnamemodify(relative_file, ":t") .. ":")
										table.insert(processed_lines, string.rep("─", 50))
										table.insert(processed_lines, "")
										
										-- Add the diff content
										for _, line in ipairs(lines) do
											table.insert(processed_lines, line)
										end
										
										vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, processed_lines)
										
										-- Set diff filetype for syntax highlighting
										vim.api.nvim_buf_set_option(self.state.bufnr, "filetype", "diff")
										
										-- Add some basic diff highlighting
										local ns_id = vim.api.nvim_create_namespace("telescope_git_diff")
										vim.api.nvim_buf_clear_namespace(self.state.bufnr, ns_id, 0, -1)
										
										for i, line in ipairs(processed_lines) do
											if line:match("^%+") and not line:match("^%+%+%+") then
												-- Added lines in green
												vim.api.nvim_buf_add_highlight(self.state.bufnr, ns_id, "DiffAdd", i-1, 0, -1)
											elseif line:match("^%-") and not line:match("^%-%-%-") then
												-- Removed lines in red
												vim.api.nvim_buf_add_highlight(self.state.bufnr, ns_id, "DiffDelete", i-1, 0, -1)
											elseif line:match("^@@") then
												-- Hunk headers in blue
												vim.api.nvim_buf_add_highlight(self.state.bufnr, ns_id, "DiffText", i-1, 0, -1)
											elseif line:match("^Commit:") or line:match("^Date:") or line:match("^Author:") or line:match("^Message:") then
												-- Header info in bold
												vim.api.nvim_buf_add_highlight(self.state.bufnr, ns_id, "Title", i-1, 0, -1)
											end
										end
									else
										-- If no diff (maybe first commit), show the full file
										local cmd_show = string.format(
											"git show %s:%s",
											entry.value.hash,
											vim.fn.shellescape(relative_file)
										)
										local handle_show = io.popen(cmd_show)
										if handle_show then
											local content = handle_show:read("*all")
											handle_show:close()
											
											local lines = vim.split(content, "\n")
											local header = {
												"Commit: " .. entry.value.hash .. " (Initial version)",
												"Date: " .. entry.value.date,
												"Author: " .. entry.value.author,
												"Message: " .. entry.value.message,
												"",
												"File content at this commit:",
												string.rep("─", 50),
												""
											}
											
											-- Combine header with file content
											for i, line in ipairs(header) do
												table.insert(lines, i, line)
											end
											
											vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
											
											-- Set original filetype for syntax highlighting of content
											local ft = vim.filetype.match({ filename = relative_file })
											if ft then
												vim.api.nvim_buf_set_option(self.state.bufnr, "filetype", ft)
											end
										end
									end
								end
							end,
						}),
						attach_mappings = function(prompt_bufnr, map)
							actions.select_default:replace(function()
								local selection = action_state.get_selected_entry()
								actions.close(prompt_bufnr)

								-- Show diff between current file and selected commit
								vim.cmd(
									"DiffviewOpen "
										.. selection.value.hash
										.. "^.."
										.. selection.value.hash
										.. " -- "
										.. relative_file
								)
							end)

							map("i", "<C-d>", function()
								local selection = action_state.get_selected_entry()
								actions.close(prompt_bufnr)
								-- Show what changed in this commit for this file
								vim.cmd(
									"DiffviewOpen "
										.. selection.value.hash
										.. "^.."
										.. selection.value.hash
										.. " -- "
										.. relative_file
								)
							end)

							map("i", "<C-s>", function()
								local selection = action_state.get_selected_entry()
								actions.close(prompt_bufnr)
								-- Show the file at this commit
								vim.cmd("!git show " .. selection.value.hash .. ":" .. relative_file .. " | less")
							end)

							return true
						end,
					})
					:find()
			end, { desc = "Git file history for current file" })
			keymap.set("n", "<leader>tn", function()
				require("telescope.builtin").find_files({
					cwd = vim.fn.stdpath("config"),
				})
			end, { desc = "Search neovim config" })
			keymap.set("n", "<leader>td", function()
				builtin.diagnostics({ bufnr = 0 })
			end, { desc = "Search diagnostics in current buffer" })

			-- Slightly advanced example of overriding default behavior and theme
			vim.keymap.set("n", "<leader>/", function()
				-- You can pass additional configuration to Telescope to change the theme, layout, etc.
				builtin.current_buffer_fuzzy_find(require("telescope.themes").get_dropdown({
					winblend = 10,
					previewer = false,
				}))
			end, { desc = "[/] Fuzzily search in current buffer" })

			-- It's also possible to pass additional configuration options.
			--  See `:help telescope.builtin.live_grep()` for information about particular keys
			vim.keymap.set("n", "<leader>t/", function()
				builtin.live_grep({
					grep_open_files = true,
					prompt_title = "Live Grep in Open Files",
				})
			end, { desc = "[S]earch [/] in Open Files" })
			require("plugins.telescope.smartgrep").setup()
			require("telescope").load_extension("ui-select")
			require("telescope").load_extension("fzf")
		end,
	},
}
