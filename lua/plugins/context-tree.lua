return {
	{
		"nvim-treesitter/nvim-treesitter-context",
		lazy = false, -- Adjust this based on whether you want to load it lazily or not
		priority = 1000, -- Adjust the priority if needed
		config = function()
			require("treesitter-context").setup({
				-- enable = true, -- Enable this plugin (Can be enabled/disabled later via commands)
				-- max_lines = 0, -- How many lines the window should span. Values <= 0 mean no limit.
				-- min_window_height = 0, -- Minimum editor window height to enable context. Values <= 0 mean no limit.
				-- line_numbers = true,
				-- multiline_threshold = 20, -- Maximum number of lines to show for a single context
				-- trim_scope = 'outer', -- Which context lines to discard if `max_lines` is exceeded. Choices: 'inner', 'outer'
				mode = "topline", -- Line used to calculate context. Choices: 'cursor', 'topline'
				-- separator = nil, -- Separator between context and content. Should be a single character string, like '-'.
				-- zindex = 20, -- The Z-index of the context window
				-- on_attach = nil, -- (fun(buf: integer): boolean) return false to disable attaching
			})
		end,
	},
}
