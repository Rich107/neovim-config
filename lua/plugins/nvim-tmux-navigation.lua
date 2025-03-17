if not vim.env.IN_CONTAINER then
	return {
		"christoomey/vim-tmux-navigator",
		vim.keymap.set("n", "<C-h>", ":TmuxNavigateLeft<CR>"),
		vim.keymap.set("n", "<C-j>", ":TmuxNavigateDown<CR>"),
		vim.keymap.set("n", "<C-k>", ":TmuxNavigateUp<CR>"),
		vim.keymap.set("n", "<C-l>", ":TmuxNavigateRight<CR>"),
	}
else
	-- This is until I get TMUX in TMUX In a place that I am happy with it if ever...
	vim.api.nvim_set_keymap("n", "<C-h>", "<C-w>h", { noremap = true, silent = true })
	vim.api.nvim_set_keymap("n", "<C-j>", "<C-w>j", { noremap = true, silent = true })
	vim.api.nvim_set_keymap("n", "<C-k>", "<C-w>k", { noremap = true, silent = true })
	vim.api.nvim_set_keymap("n", "<C-l>", "<C-w>l", { noremap = true, silent = true })
	return {} -- No plugins returned
end
