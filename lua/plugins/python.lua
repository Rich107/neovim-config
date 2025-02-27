return {
	{
		"stevanmilic/nvim-lspimport",
		config = function()
			vim.keymap.set("n", "<leader>io", require("lspimport").import, { noremap = true, silent = true })
		end,
	},
	{
		"kiyoon/python-import.nvim",
		build = "pipx install . --force",
		ft = "python",
		keys = {
			{
				"<leader>ip",
				function()
					require("python_import.api").add_import_current_word_and_notify()
				end,
				mode = { "i", "n" },
				silent = true,
				desc = "Add python import",
				ft = "python",
			},
		},
	},
}
