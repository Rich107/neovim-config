return {
	"m-test/vim-test",
	dependencies = {
		"preservim/vimux",
	},
	config = function()
		vim.keymap.set(
			"n",
			"<leader>rt",
			":TestNearest<CR>",
			{ desc = "Test Nearest - The nearest test to your curosr" }
		)
		vim.keymap.set("n", "<leader>rT", ":TestFile<CR>", { desc = "TestFile - Test the whole open file" })
		vim.keymap.set("n", "<leader>ra", ":TestSuite<CR>", { desc = "TestSuite - Run all the tests" })
		vim.keymap.set("n", "<leader>rl", ":TestLast<CR>", { desc = "TestLast - Runs the last test again" })
		vim.keymap.set("n", "<leader>rv", ":TestVisit<CR>", { desc = "Test Visit - The last test you ran" })
		vim.cmd("let test#strategy = 'vimux'")
		vim.cmd("let test#python#runner = 'pytest'")

		-- This is working for PA-Leaderboard app
		-- vim.cmd("let test#python#pytest#executable='docker compose exec rest-api pytest --disable-warnings -vv '")

		-- This is working for Legl app (python only)
		vim.cmd([[
		        let g:test#python#pytest#executable = 'docker compose exec server pytest --disable-warnings -vv'
		        ]])
	end,
}
