return {
	"nvim-neotest/neotest",
	enable = false,
	dependencies = {
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
					-- runner = function()
					-- 	return { "docker", "compose", "exec", "rest-api", "pytest" }
					-- end,
					-- Custom python path for the runner.
					-- Can be a string or a list of strings.
					-- Can also be a function to return dynamic value.
					-- If not provided, the path will be inferred by checking for
					-- virtual envs in the local directory and for Pipenev/Poetry configs
					-- python = "../pa_env/bin/python",
					python = function()
						return "docker compose exec rest-api python"
					end,
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
