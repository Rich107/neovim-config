return {
	"m-test/vim-test",
	dependencies = {
		"preservim/vimux",
	},
	config = function()
		vim.keymap.set("n", "<leader>rt", ":TestNearest<CR>", { desc = "Test Nejrest" })
		vim.keymap.set("n", "<leader>rT", ":TestFile<CR>", { desc = "TestFile" })
		vim.keymap.set("n", "<leader>ra", ":TestSuite<CR>", { desc = "TestSuite" })
		vim.keymap.set("n", "<leader>rl", ":TestLast<CR>", { desc = "TestLast" })
		vim.keymap.set("n", "<leader>rg", ":TestVisit<CR>", { desc = "TestVisit" })
		vim.cmd("let test#strategy = 'vimux'")
	end,
}
