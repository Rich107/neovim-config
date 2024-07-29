return {
	"vim-test/vim-test",
	dependencies = {
		"preservim/vimux",
	},
	config = function()
		vim.keymap.set("n", "<leader>rt", ":TestNearest<CR>", {})
		vim.keymap.set("n", "<leader>rtf", ":TestFile<CR>", {})
		vim.keymap.set("n", "<leader>rta", ":TestSuite<CR>", {})
		vim.keymap.set("n", "<leader>rtl", ":TestLast<CR>", {})
		vim.keymap.set("n", "<leader>rtg", ":TestVisit<CR>", {})
		vim.cmd("let test#strategy = 'vimux'")
	end,
}
