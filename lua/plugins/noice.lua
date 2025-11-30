return {
	"folke/noice.nvim",
	event = "VeryLazy",
	opts = {
		-- add any options here
	},
	dependencies = {
		-- if you lazy-load any plugin below, make sure to add proper `module="..."` entries
		"MunifTanjim/nui.nvim",
		-- OPTIONAL:
		--   `nvim-notify` is only needed, if you want to use the notification view.
		--   If not available, we use `mini` as the fallback
		"rcarriga/nvim-notify",
	},
	config = function()
		require("notify").setup({
			background_colour = "#000000",
		})

		require("noice").setup({
			cmdline = {
				enabled = false, -- disable noice cmdline completely
			},
			messages = {
				enabled = false, -- disable noice messages
			},
			routes = {
				{
					filter = {
						any = {
							{ event = "msg_show", find = "redraw" },
							{ event = "msg_show", find = "call delete" },
							{ event = "msg_show", find = "fugitive" },
							{ event = "msg_show", find = "checktime" },
							{ event = "msg_show", find = "Resume" },
							{ event = "msg_showcmd" },
							{ event = "cmdline", find = "redraw" },
							{ event = "cmdline", find = "call delete" },
							{ event = "cmdline", find = "fugitive" },
						},
					},
					opts = { skip = true },
				},
			},
			sections = {
				messages = {
					enabled = false, -- enables the Noice messages UI
					-- view = "notify", -- default view for messages
					-- view_error = "notify", -- view for errors
					-- view_warn = "notify", -- view for warnings
					-- view_history = "messages", -- view for :messages
					-- view_search = "virtualtext", -- view for search count messages. Set to `false` to disable
				},
				lualine_x = {
					{
						require("noice").api.status.message.get_hl,
						cond = require("noice").api.status.message.has,
					},
					{
						require("noice").api.status.command.get,
						cond = require("noice").api.status.command.has,
						color = { fg = "#ff9e64" },
					},
					{
						require("noice").api.status.mode.get,
						cond = require("noice").api.status.mode.has,
						color = { fg = "#ff9e64" },
					},
					{
						require("noice").api.status.search.get,
						cond = require("noice").api.status.search.has,
						color = { fg = "#ff9e64" },
					},
				},
			},
		})
	end,
}
