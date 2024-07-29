vim.cmd("set expandtab")
vim.cmd("set tabstop=2")
vim.cmd("set softtabstop=2")
vim.cmd("set shiftwidth=2")
vim.g.mapleader = " "
vim.g.background = "light"

local keymap = vim.keymap -- for conciseness

vim.opt.swapfile = false

-- Navigate vim panes better
keymap.set('n', '<c-k>', ':wincmd k<CR>')
keymap.set('n', '<c-j>', ':wincmd j<CR>')
keymap.set('n', '<c-h>', ':wincmd h<CR>')
keymap.set('n', '<c-l>', ':wincmd l<CR>')
vim.wo.number = true

---------------------
-- General Key maps -------------------
keymap.set("n", "<leader>cs", "<cmd>setlocal spell!<CR>", { desc = "Toggles spellchecker" })

keymap.set("n", "<leader>ch", "<cmd>TSBufToggle highlight<CR>", { desc = "Toggles spellchecker" })

-- use jk to exit insert mode
keymap.set("i", "jk", "<ESC>", { desc = "Exit insert mode with jk" })

-- clear search highlights
keymap.set("n", "<leader>nh", ":nohl<CR>", { desc = "Clear search highlights" })

-- delete single character without copying into register
keymap.set("n", "x", '"_x')

-- increment/decrement numbers
keymap.set("n", "<leader>+", "<C-a>", { desc = "Increment number" }) -- increment
keymap.set("n", "<leader>-", "<C-x>", { desc = "Decrement number" }) -- decrement

-- stop me from using the arrow keys:
keymap.set({ "n", "i" }, "<up>", "<nop>")
keymap.set({ "n", "i" }, "<down>", "<nop>")
keymap.set({ "n", "i" }, "<left>", "<nop>")
keymap.set({ "n", "i" }, "<right>", "<nop>")

-- faster movments with capitals:
keymap.set({ "o", "v", "n" }, "H", "^", { desc = "Move Left super fast" })
keymap.set({ "o", "v", "n" }, "L", "$", { desc = "Move Right super fast" }) -- Move to nd of line
keymap.set({ "o", "v", "n" }, "J", "}", { desc = "Move Down One Paragraph Super Fast" }) -- Move to next paragraph up
keymap.set({ "o", "v", "n" }, "K", "{", { desc = "Move Up One Paragraph Super Fast" })

-- move through jump history
keymap.set("n", "<leader>h", "<C-o>", { desc = "Jump back in history" })
keymap.set("n", "<leader>l", "<C-i>", { desc = "Jump back in history" })

-- window management
keymap.set("n", "<leader>wv", "<C-w>v", { desc = "Split window vertically" }) -- split window vertically
keymap.set("n", "<leader>wh", "<C-w>s", { desc = "Split window horizontally" }) -- split window horizontally
keymap.set("n", "<leader>we", "<C-w>=", { desc = "Make splits equal size" }) -- make split windows equal width & height
keymap.set("n", "<leader>wx", "<cmd>close<CR>", { desc = "Close current split" }) -- close current split window
keymap.set("n", "<leader>wo", "<cmd>only<CR>", { desc = "Close all but the current split" }) -- close current split window

-- Moving Lines up and down
keymap.set("v", "<C-j>", ":m'>+<CR>gv=gv", { desc = "Move line down in visual mode" })
keymap.set("v", "<C-k>", ":m-2<CR>gv=gv", { desc = "Move line up in visual mode" })

-- closeing and saving
keymap.set("n", "<leader>qq", "<cmd>q<CR>", { desc = "Close" })
keymap.set("n", "<leader>qw", "<cmd>wq<CR>", { desc = "Save and Close" })

