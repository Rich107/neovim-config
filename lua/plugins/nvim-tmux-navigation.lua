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
	vim.keymap.set("n", "<C-h>", "<C-w>h", { silent = true })
	vim.keymap.set("n", "<C-j>", "<C-w>j", { silent = true })
	vim.keymap.set("n", "<C-k>", "<C-w>k", { silent = true })
	vim.keymap.set("n", "<C-l>", "<C-w>l", { silent = true })
	return {} -- No plugins returned
end
