return {
	"nvim-lua/plenary.nvim", -- using plenary as dependency since it's likely already installed
	config = function()
		local function update_nvim_config()
			local timestamp = os.date("%Y%m%d_%H%M%S")
			local config_dir = vim.fn.expand("~/.config/nvim")
			local backup_dir = vim.fn.expand("~/.config/nvim_backup_" .. timestamp)

			print("Nvim config: ")
			print("Creating backup at: " .. backup_dir)

			-- Create backup
			local backup_result = vim.fn.system("cp -r " .. config_dir .. " " .. backup_dir)
			if vim.v.shell_error ~= 0 then
				print("Error: Failed to create backup")
				return
			end

			-- Remove current config
			local remove_result = vim.fn.system("rm -rf " .. config_dir)
			if vim.v.shell_error ~= 0 then
				print("Error: Failed to remove current config")
				-- Restore backup
				vim.fn.system("mv " .. backup_dir .. " " .. config_dir)
				return
			end

			-- Clone new config
			local clone_result = vim.fn.system("git clone https://github.com/Rich107/neovim-config.git " .. config_dir)

			if vim.v.shell_error ~= 0 then
				print("Error: Git clone failed, restoring backup...")
				-- Restore backup
				vim.fn.system("mv " .. backup_dir .. " " .. config_dir)
				print("Backup restored successfully")
			else
				print("Successfully updated nvim config!")
				-- Remove backup on success
				vim.fn.system("rm -rf " .. backup_dir)
				print("Backup cleaned up")
				print("Please restart nvim to use the new configuration")
			end
		end

		vim.keymap.set("n", "<leader>nu", update_nvim_config, { desc = "Update nvim config from GitHub" })
	end,
}
