return {
	{
		"stevanmilic/nvim-lspimport",
		enabled = false,
		config = function()
			vim.keymap.set("n", "<leader>io", require("lspimport").import, { noremap = true, silent = true })
		end,
	},
}
