if vim.env.HOME == "/Users/richardellison" then
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
                vim.cmd("let test#strategy = 'neovim'")
            end
            vim.cmd("let test#python#runner = 'pytest'")

            -- This is working for Legl app (python only)

            if vim.env.HOME ~= "/Users/richardellison" and vim.env.PROJECT_ID == "live-personal-pa-leaderboard" then
                -- running on container for pa project
                vim.cmd("let g:test#python#pytest#executable='pytest --disable-warnings -vv '")
            elseif vim.env.HOME == "/Users/richardellison" and vim.env.PROJECT_ID == "live-personal-pa-leaderboard" then
                -- running on host for pa project
                vim.cmd(
                    "let g:test#python#pytest#executable='docker compose exec rest-api pytest --disable-warnings -vv '"
                )
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
                vim.cmd(
                    "let g:test#python#pytest#executable='docker compose exec rest-api pytest --disable-warnings -vv '"
                )
            end
        end,
    }
else
    return {
        "nvim-neotest/neotest",
        enable = false,
        dependencies = {
            "vim-test/vim-test",
            "nvim-neotest/nvim-nio",
            "nvim-lua/plenary.nvim",
            "antoinemadec/FixCursorHold.nvim",
            "nvim-treesitter/nvim-treesitter",
            "marilari88/neotest-vitest",
            "nvim-neotest/neotest-python",
        },
        config = function()
            require("neotest").setup({
                adapters = {
                    require("neotest-vitest"),
                    require("neotest-python")({
                        -- Extra arguments for nvim-dap configuration
                        -- See https://github.com/microsoft/debugpy/wiki/Debug-configuration-settings for values
                        -- dap = { justMyCode = false },
                        -- Command line arguments for runner
                        -- Can also be a function to return dynamic values
                        -- args = {
                        -- 	"docker",
                        -- 	"compose",
                        -- 	"exec",
                        -- 	"rest-api",
                        -- 	"pytest",
                        -- 	"--log-level",
                        -- 	"DEBUG",
                        -- },
                        -- Runner to use. Will use pytest if available by default.
                        -- Can be a function to return dynamic value.
                        -- runner = "docker compose exec rest-api pytest",
                        -- Custom python path for the runner.
                        -- Can be a string or a list of strings.
                        -- Can also be a function to return dynamic value.
                        -- If not provided, the path will be inferred by checking for
                        -- virtual envs in the local directory and for Pipenev/Poetry configs
                        -- python = "../pa_env/bin/python",
                        -- Returns if a given file path is a test file.
                        -- NB: This function is called a lot so don't perform any heavy tasks within it.
                        test_file = function(file_path)
                            return file_path:match("_test%.py$") or file_path:match("test_.+%.py$")
                        end,
                        -- instances for files containing a parametrize mark (default: false)
                        -- pytest_discover_instances = true,
                    }),
                },
            })

            vim.keymap.set("n", "<leader>rt", require("neotest").run.run(), { desc = "Run nearest test" })
            vim.keymap.set(
                "n",
                "<leader>rT",
                require("neotest").run.run(vim.fn.expand("%")),
                { desc = "TestFile - Test the whole open file" }
            )
            -- vim.keymap.set(
            -- 	"n",
            -- 	"<leader>ra",
            -- 	require("neotest").run.run_last,
            -- 	{ desc = "TestSuite - Run all the tests" }
            -- )
            vim.keymap.set(
                "n",
                "<leader>rl",
                require("neotest").run.run_last,
                { desc = "TestLast - Runs the last test again" }
            )
        end,
    }
end
