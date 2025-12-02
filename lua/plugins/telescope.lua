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
					-- Customizing path display to show only the filename and first two parent folders.
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
					find_command = { "rg", "--hidden", "--files" },
					prompt_prefix = "🔭 ",
				})
			end, { desc = "Fuzzy find files + hidden files" })
			
			keymap.set("n", "<leader>tF", function()
				require("telescope.builtin").find_files({
					find_command = { "rg", "--no-ignore", "--hidden", "--files" },
					prompt_prefix = "🔭 ",
				})
			end, { desc = "Fuzzy find ALL files (includes gitignored)" })

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
			keymap.set("n", "<leader>tr", function()
				require("plugins.telescope.justfile-picker").pick_just_recipe()
			end, { desc = "Pick and run Just recipe in tmux" })
			keymap.set("n", "<leader>tp", function()
				require("plugins.telescope.pr-label-picker").pick_pr_by_label()
			end, { desc = "Pick PRs by label" })
		keymap.set("n", "<leader>tR", builtin.resume, { desc = "Resume last Telescope search" })
			keymap.set("n", "<leader>ts", builtin.live_grep, { desc = "Find string in cwd" })
			
			keymap.set("v", "<leader>ts", function()
				-- Get the visually selected text
				vim.cmd('noau normal! "vy"')
				local selected_text = vim.fn.getreg('v')
				-- Escape special regex characters
				local escaped_text = selected_text:gsub("[%(%)%[%]%{%}%^%$%*%+%?%.%|%-]", "\\%1")
				-- Start live_grep with the escaped text as default
				builtin.live_grep({ default_text = escaped_text })
			end, { desc = "Find selected string in cwd" })
			
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
			keymap.set("n", "<leader>tb", function()
				require("plugins.telescope.branch-picker").pick_branch()
			end, { desc = "Git branches" })

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

				-- Get git log for the current file with full commit messages
				local cmd = string.format(
					"git log --pretty=format:'COMMIT_START%%n%%h|%%ad|%%an|%%s%%n%%B%%nCOMMIT_END' --date=short --follow -- %s",
					vim.fn.shellescape(relative_file)
				)

				local results = {}
				local handle = io.popen(cmd)
				if handle then
					local current_commit = nil
					local body_lines = {}
					local in_body = false
					
					for line in handle:lines() do
						if line == "COMMIT_START" then
							current_commit = nil
							body_lines = {}
							in_body = false
						elseif line == "COMMIT_END" then
							if current_commit then
								-- Process the body: remove the title line and clean up
								local body = ""
								if #body_lines > 1 then
									-- Skip the first line (title) and any empty lines after it
									local start_idx = 2
									while start_idx <= #body_lines and body_lines[start_idx]:match("^%s*$") do
										start_idx = start_idx + 1
									end
									
									if start_idx <= #body_lines then
										local body_content = {}
										for i = start_idx, #body_lines do
											table.insert(body_content, body_lines[i])
										end
										body = table.concat(body_content, "\n"):gsub("%s+$", "")
									end
								end
								
								current_commit.body = body
								table.insert(results, current_commit)
							end
						elseif not in_body then
							-- Parse the header line
							local hash, date, author, title = line:match("([^|]+)|([^|]+)|([^|]+)|(.+)")
							if hash then
								current_commit = {
									hash = hash,
									date = date,
									author = author,
									title = title,
									display = string.format("%-8s %s %-15s %s", hash, date, author, title),
								}
								in_body = true
							end
						else
							-- Collect body lines
							table.insert(body_lines, line)
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
										.. entry.title
										.. " "
										.. entry.body,
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
										table.insert(processed_lines, "Title: " .. entry.value.title)
										if entry.value.body and entry.value.body ~= "" then
											table.insert(processed_lines, "")
											-- Split body into lines and wrap long lines
											local body_lines = vim.split(entry.value.body, "\n")
											for _, body_line in ipairs(body_lines) do
												if body_line:gsub("%s", "") ~= "" then -- Skip empty lines
													-- Wrap long lines at 70 characters
													local wrapped_lines = {}
													local line = body_line
													while #line > 68 do -- 68 to account for 2-space indent
														local break_pos = 68
														-- Try to break at a word boundary
														for i = 68, 40, -1 do
															if line:sub(i, i):match("%s") then
																break_pos = i
																break
															end
														end
														table.insert(wrapped_lines, "  " .. line:sub(1, break_pos):gsub("%s+$", ""))
														line = line:sub(break_pos + 1):gsub("^%s+", "")
													end
													if #line > 0 then
														table.insert(wrapped_lines, "  " .. line)
													end
													
													for _, wrapped_line in ipairs(wrapped_lines) do
														table.insert(processed_lines, wrapped_line)
													end
												else
													-- Preserve empty lines in commit body
													table.insert(processed_lines, "")
												end
											end
										end
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
										elseif line:match("^Commit:") or line:match("^Date:") or line:match("^Author:") or line:match("^Title:") then
											-- Header info in bold
											vim.api.nvim_buf_add_highlight(self.state.bufnr, ns_id, "Title", i-1, 0, -1)
									elseif line:match("^  ") then
										-- Commit body (indented) in a softer color
										vim.api.nvim_buf_add_highlight(self.state.bufnr, ns_id, "Comment", i-1, 0, -1)
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
												"Title: " .. entry.value.title,
											}
											
											if entry.value.body and entry.value.body ~= "" then
												table.insert(header, "")
												local body_lines = vim.split(entry.value.body, "\n")
												for _, body_line in ipairs(body_lines) do
													if body_line:gsub("%s", "") ~= "" then
														-- Wrap long lines at 70 characters
														local wrapped_lines = {}
														local line = body_line
														while #line > 68 do
															local break_pos = 68
															-- Try to break at a word boundary
															for i = 68, 40, -1 do
																if line:sub(i, i):match("%s") then
																	break_pos = i
																	break
																end
															end
															table.insert(wrapped_lines, "  " .. line:sub(1, break_pos):gsub("%s+$", ""))
															line = line:sub(break_pos + 1):gsub("^%s+", "")
														end
														if #line > 0 then
															table.insert(wrapped_lines, "  " .. line)
														end
														
														for _, wrapped_line in ipairs(wrapped_lines) do
															table.insert(header, wrapped_line)
														end
													else
														table.insert(header, "")
													end
												end
											end
											
											table.insert(header, "")
											table.insert(header, "File content at this commit:")
											table.insert(header, string.rep("─", 50))
											table.insert(header, "")
											
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

			-- Visual mode git history for selected lines
			keymap.set("v", "<leader>th", function()
				local current_file = vim.fn.expand("%:p")
				if current_file == "" then
					vim.notify("No file is currently open", vim.log.levels.WARN)
					return
				end

				-- Get visual selection line numbers
				-- Exit visual mode to set the marks properly
				vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Esc>', true, false, true), 'nx', false)
				local start_line = vim.fn.line("'<")
				local end_line = vim.fn.line("'>")
				
				-- Validate line numbers
				if start_line == 0 or end_line == 0 then
					vim.notify("Could not determine selected line range", vim.log.levels.ERROR)
					return
				end
				
				local relative_file = vim.fn.fnamemodify(current_file, ":.")
				local pickers = require("telescope.pickers")
				local finders = require("telescope.finders")
				local conf = require("telescope.config").values
				local actions = require("telescope.actions")
				local action_state = require("telescope.actions.state")
				local previewers = require("telescope.previewers")

				-- Use git log -L to get history for specific line range
				-- First get the commit hashes that affected these lines
				local cmd_hashes = string.format(
					"git log -L %d,%d:%s --pretty=format:'%%h' --no-patch",
					start_line,
					end_line,
					vim.fn.shellescape(relative_file)
				)
				
				local commit_hashes = {}
				local handle_hashes = io.popen(cmd_hashes)
				if handle_hashes then
					for line in handle_hashes:lines() do
						if line:match("^%w+$") then -- Only commit hashes
							table.insert(commit_hashes, line)
						end
					end
					handle_hashes:close()
				end
				
				-- Now get detailed info for each commit
				local results = {}
				for _, hash in ipairs(commit_hashes) do
					local cmd_detail = string.format(
						"git show --no-patch --pretty=format:'%%h|%%ad|%%an|%%s|%%B' --date=short %s",
						hash
					)
					
					local handle_detail = io.popen(cmd_detail)
					if handle_detail then
						local output = handle_detail:read("*all")
						handle_detail:close()
						
						if output and output ~= "" then
							local lines = vim.split(output, "\n")
							if #lines > 0 then
								local header = lines[1]
								local hash_part, date, author, title, body_start = header:match("([^|]+)|([^|]+)|([^|]+)|([^|]+)|(.*)") 
								
								-- Collect body (everything after the header line)
								local body_lines = {body_start or ""}
								for i = 2, #lines do
									table.insert(body_lines, lines[i])
								end
								local body = table.concat(body_lines, "\n"):gsub("^%s+", ""):gsub("%s+$", "")
								
								-- Remove the title from body if it's duplicated
								if body:sub(1, #title) == title then
									body = body:sub(#title + 1):gsub("^%s+", "")
								end
								
								table.insert(results, {
									hash = hash_part,
									date = date,
									author = author,
									title = title,
									body = body,
									display = string.format("%-8s %s %-15s %s", hash_part, date, author, title),
								})
							end
						end
					end
				end

				if #results == 0 then
					vim.notify(string.format("No git history found for lines %d-%d in %s", start_line, end_line, relative_file), vim.log.levels.WARN)
					return
				end

				pickers
					.new({}, {
						prompt_title = string.format("Git History: Lines %d-%d in %s", start_line, end_line, vim.fn.fnamemodify(relative_file, ":t")),
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
										.. entry.title
										.. " "
										.. entry.body,
								}
							end,
						}),
						sorter = conf.generic_sorter({}),
						previewer = previewers.new_buffer_previewer({
							title = "Changes in Selected Lines",
							get_buffer_by_name = function(_, entry)
								return "line_diff:" .. entry.value.hash .. ":" .. relative_file .. ":" .. start_line .. "-" .. end_line
							end,
							define_preview = function(self, entry, status)
								-- Get the diff for this specific commit and line range
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
										table.insert(processed_lines, "Title: " .. entry.value.title)
										table.insert(processed_lines, string.format("Lines: %d-%d", start_line, end_line))
										
										if entry.value.body and entry.value.body ~= "" then
											table.insert(processed_lines, "")
											-- Split body into lines and wrap long lines
											local body_lines = vim.split(entry.value.body, "\n")
											for _, body_line in ipairs(body_lines) do
												if body_line:gsub("%s", "") ~= "" then -- Skip empty lines
													-- Wrap long lines at 70 characters
													local wrapped_lines = {}
													local line = body_line
													while #line > 68 do -- 68 to account for 2-space indent
														local break_pos = 68
														-- Try to break at a word boundary
														for i = 68, 40, -1 do
															if line:sub(i, i):match("%s") then
																break_pos = i
																break
															end
														end
														table.insert(wrapped_lines, "  " .. line:sub(1, break_pos):gsub("%s+$", ""))
														line = line:sub(break_pos + 1):gsub("^%s+", "")
													end
													if #line > 0 then
														table.insert(wrapped_lines, "  " .. line)
													end
													
													for _, wrapped_line in ipairs(wrapped_lines) do
														table.insert(processed_lines, wrapped_line)
													end
												else
													-- Preserve empty lines in commit body
													table.insert(processed_lines, "")
												end
											end
										end
										table.insert(processed_lines, "")
										table.insert(processed_lines, "Changes affecting selected lines:")
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
										local ns_id = vim.api.nvim_create_namespace("telescope_git_line_diff")
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
											elseif line:match("^Commit:") or line:match("^Date:") or line:match("^Author:") or line:match("^Title:") or line:match("^Lines:") then
												-- Header info in bold
												vim.api.nvim_buf_add_highlight(self.state.bufnr, ns_id, "Title", i-1, 0, -1)
											elseif line:match("^  ") then
												-- Commit body (indented) in a softer color
												vim.api.nvim_buf_add_highlight(self.state.bufnr, ns_id, "Comment", i-1, 0, -1)
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

							return true
						end,
					})
					:find()
			end, { desc = "Git history for selected lines" })

			keymap.set("n", "<leader>tn", function()
				require("telescope.builtin").find_files({
					cwd = vim.fn.stdpath("config"),
				})
			end, { desc = "Search neovim config" })
			keymap.set("n", "<leader>td", function()
				builtin.diagnostics({ bufnr = 0 })
			end, { desc = "Search diagnostics in current buffer" })
			keymap.set("n", "<leader>tm", builtin.lsp_document_symbols, { desc = "Search symbols in current buffer" })
			keymap.set("n", "<leader>tM", function()
				vim.ui.input({ prompt = "Enter search query: " }, function(query)
					if query and query ~= "" then
						builtin.lsp_workspace_symbols({
							query = query,
							layout_strategy = "vertical",
							previewer = true,
						})
					end
				end)
			end, { desc = "Search symbols in workspace" })

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
