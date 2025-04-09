return {
	"vim-test/vim-test",
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
		if vim.env.HOME == "/Users/richardellison" then
			vim.cmd("let test#strategy = 'vimux'")
		else
			vim.cmd("let test#strategy = 'nvim'")
		end
		vim.cmd("let test#python#runner = 'pytest'")

		-- This is working for Legl app (python only)

		if vim.env.HOME ~= "/Users/richardellison" and vim.env.PROJECT_ID == "live-personal-pa-leaderboard" then
			-- running on container for pa project
			vim.cmd("let g:test#python#pytest#executable='pytest --disable-warnings -vv '")
		elseif vim.env.HOME == "/Users/richardellison" and vim.env.PROJECT_ID == "live-personal-pa-leaderboard" then
			-- running on host for pa project
			vim.cmd("let g:test#python#pytest#executable='docker compose exec rest-api pytest --disable-warnings -vv '")
		elseif vim.env.HOME == "/Users/richardellison" and vim.env.PROJECT_ID ~= "live-personal-pa-leaderboard" then
			-- running on host for legl project
			vim.cmd(
				"let g:test#python#pytest#executable='docker compose exec server pytest --disable-warnings -vv --create-db'"
			)
		elseif vim.env.HOME ~= "/Users/richardellison" and vim.env.PROJECT_ID ~= "live-personal-pa-leaderboard" then
			-- running on container for legl project
			vim.cmd([[
                    let g:test#python#pytest#executable = 'pytest --disable-warnings -vv --create-db'
                    ]])
		else
			vim.cmd("let g:test#python#pytest#executable='docker compose exec rest-api pytest --disable-warnings -vv '")
		end
	end,
}
