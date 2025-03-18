if not vim.env.DEVPOD then
	vim.notify("We are Running on the host")
	return {
		"christoomey/vim-tmux-navigator",
		vim.keymap.set("n", "<C-h>", ":TmuxNavigateLeft<CR>"),
		vim.keymap.set("n", "<C-j>", ":TmuxNavigateDown<CR>"),
		vim.keymap.set("n", "<C-k>", ":TmuxNavigateUp<CR>"),
		vim.keymap.set("n", "<C-l>", ":TmuxNavigateRight<CR>"),
	}
else
	-- This is until I get TMUX in TMUX In a place that I am happy with it if ever...
	vim.api.nvim_set_keymap("n", "<C-h>", "<Cmd>wincmd h<CR>", { noremap = true, silent = true })
	vim.api.nvim_set_keymap("n", "<C-j>", "<Cmd>wincmd j<CR>", { noremap = true, silent = true })
	vim.api.nvim_set_keymap("n", "<C-k>", "<Cmd>wincmd k<CR>", { noremap = true, silent = true })
	vim.api.nvim_set_keymap("n", "<C-l>", "<Cmd>wincmd l<CR>", { noremap = true, silent = true })
	vim.notify("We are Running in a container")
	return {} -- No plugins returned
end
