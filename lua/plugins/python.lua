return {
	{
		"stevanmilic/nvim-lspimport",
		config = function()
			vim.keymap.set("n", "<leader>io", require("lspimport").import, { noremap = true, silent = true })
		end,
	},
}
