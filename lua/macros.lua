local function log_variable()
	-- Use feedkeys to send the key sequence
	vim.api.nvim_feedkeys(
		vim.api.nvim_replace_termcodes('yoconsole.log("<Esc>pa:", <Esc>pa);<Esc>', true, true, true),
		"n",
		true
	)
end

-- vim.api.nvim_set_keymap("n", "<leader>L", "", {
-- 	noremap = true,
-- 	silent = true,
-- 	callback = log_variable,
-- 	desc = "Log variable to console for js",
-- })

vim.api.nvim_set_keymap("v", "<leader>L", "", {
	noremap = true,
	silent = true,
	callback = log_variable,
	desc = "Log variable to console for js",
})
