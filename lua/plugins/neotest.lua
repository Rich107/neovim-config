if vim.env.HOME == "/Users/richardellison" then
    return {}
else
    return {
        "nvim-neotest/neotest",
        dependencies = {
            "nvim-neotest/nvim-nio",
            "nvim-lua/plenary.nvim",
            "nvim-treesitter/nvim-treesitter",
            "nvim-neotest/neotest-python",
        },
        keys = {
            {
                "<leader>r",
                "",
                desc = "+test",
            },
            {
                "<leader>rT",
                function()
                    require("neotest").run.run(vim.fn.expand("%"))
                end,
                desc = "Run File (Neotest)",
            },
            {
                "<leader>ra",
                function()
                    require("neotest").run.run(vim.uv.cwd())
                end,
                desc = "Run All Test Files (Neotest)",
            },
            {
                "<leader>rt",
                function()
                    require("neotest").run.run()
                end,
                desc = "Run Nearest (Neotest)",
            },
            {
                "<leader>rl",
                function()
                    require("neotest").run.run_last()
                end,
                desc = "Run Last (Neotest)",
            },
            {
                "<leader>rs",
                function()
                    require("neotest").summary.toggle()
                end,
                desc = "Toggle Summary (Neotest)",
            },
            {
                "<leader>ro",
                function()
                    require("neotest").output.open({ enter = true, auto_close = true })
                end,
                desc = "Show Output (Neotest)",
            },
            {
                "<leader>rO",
                function()
                    require("neotest").output_panel.toggle()
                end,
                desc = "Toggle Output Panel (Neotest)",
            },
            {
                "<leader>rS",
                function()
                    require("neotest").run.stop()
                end,
                desc = "Stop (Neotest)",
            },
            {
                "<leader>rw",
                function()
                    require("neotest").watch.toggle(vim.fn.expand("%"))
                end,
                desc = "Toggle Watch (Neotest)",
            },
        },
        config = function()
            require("neotest").setup({
                adapters = {
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
        end,
    }
end
