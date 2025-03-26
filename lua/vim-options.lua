vim.cmd("set expandtab")
vim.cmd("set tabstop=4")
vim.cmd("set softtabstop=4")
vim.cmd("set shiftwidth=4")
vim.g.mapleader = " "
vim.g.background = "light"

local keymap = vim.keymap -- for conciseness

vim.o.wrap = false

vim.opt.swapfile = false

-- This allows copy paste to work in ssh connections:
local osc52 = require("vim.ui.clipboard.osc52")

vim.g.clipboard = {
    name = "OSC 52",
    copy = {
        ["+"] = osc52.copy("+"),
        ["*"] = osc52.copy("*"),
    },
    paste = {
        ["+"] = osc52.paste("+"),
        ["*"] = osc52.paste("*"),
    },
}

-- Alt key will not let me type # it types £ instead
keymap.set("i", "£", "#", { desc = "Type # instead of £" })

-- Obsidian
keymap.set("n", "<leader>ob", "<cmd>ObsidianBacklinks<CR>", { desc = "Obsidian Backlinks" })
vim.opt.conceallevel = 1 -- or 2

vim.wo.number = true

-- scroll gaps at top and bottom of page
vim.opt.scrolloff = 15

-- yank to system
keymap.set("v", "<leader>y", '"+y', { desc = "yank to buffer" })

-- line numbers
vim.opt.relativenumber = true -- show relative line numbers
vim.opt.number = true         -- shows absolute line number on cursor line (when relative number is on)

-- go to url:
vim.keymap.set("n", "gx", "<esc>:URLOpenUnderCursor<cr>")

-- General Key maps -------------------
-- keymap.set("n", "<leader>cs", "<cmd>setlocal spell!<CR>", { desc = "Toggles spellchecker" })
keymap.set("n", "<leader>sg", "zg", { desc = "Add word under cursor to spelling list" })
keymap.set("n", "<leader>sb", "zw", { desc = "Add word under cursor to wrong spelling list" })

keymap.set("n", "<leader>ch", "<cmd>TSBufToggle highlight<CR>", { desc = "Toggles spellchecker" })

-- use jk to exit insert mode
keymap.set("i", "jk", "<ESC>", { desc = "Exit insert mode with jk" })

-- clear search highlights
keymap.set("n", "<leader>nh", ":nohl<CR>", { desc = "Clear search highlights" })
-- search case sensitive only with mixed case:
vim.opt.ignorecase = true
vim.opt.smartcase = true

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
keymap.set({ "o", "v", "n" }, "L", "$", { desc = "Move Right super fast" })              -- Move to end of line
keymap.set({ "o", "v", "n" }, "J", "}", { desc = "Move Down One Paragraph Super Fast" }) -- Move to next paragraph up
keymap.set({ "o", "v", "n" }, "K", "{", { desc = "Move Up One Paragraph Super Fast" })

-- move through jump history
keymap.set("n", "<leader>h", "<C-o>", { desc = "Jump back in history" })
keymap.set("n", "<leader>l", "<C-i>", { desc = "Jump back in history" })

-- window management
keymap.set("n", "<leader>wv", "<C-w>v", { desc = "Split window vertically" })                -- split window vertically
keymap.set("n", "<leader>wh", "<C-w>s", { desc = "Split window horizontally" })              -- split window horizontally
keymap.set("n", "<leader>we", "<C-w>=", { desc = "Make splits equal size" })                 -- make split windows equal width & height
keymap.set("n", "<leader>wx", "<cmd>close<CR>", { desc = "Close current split" })            -- close current split window
keymap.set("n", "<leader>wo", "<cmd>only<CR>", { desc = "Close all but the current split" }) -- close current split window

-- Moving Lines up and down
keymap.set("v", "<C-j>", ":m'>+<CR>gv=gv", { desc = "Move line down in visual mode" })
keymap.set("v", "<C-k>", ":m-2<CR>gv=gv", { desc = "Move line up in visual mode" })

-- Closing and saving
keymap.set("n", "<leader>qq", "<cmd>q<CR>", { desc = "Close" })
keymap.set("n", "<leader>qw", "<cmd>wq<CR>", { desc = "Save and Close" })

-- Highlight text when yanking
vim.api.nvim_create_autocmd("TextYankPost", {
    desc = "Highlight when yanking (copying) text",
    group = vim.api.nvim_create_augroup("kickstart-highlight-yank", { clear = true }),
    callback = function()
        vim.highlight.on_yank()
    end,
})

vim.api.nvim_create_autocmd("BufWritePre", {
    pattern = "*.py",
    callback = function()
        local bufnr = vim.api.nvim_get_current_buf()
        local content = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
        local result = vim.system({ "ruff", "format", "-" }, { stdin = table.concat(content, "\n") }):wait()

        if result.code == 0 then
            local formatted = vim.split(result.stdout, "\n")
            vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, formatted)
        end
    end,
})

-- -- Set highlight colors (overridden by colorscheme, hence after)-- vim.api.nvim_set_hl(0, "LineNr", { fg = "#6c7086" })
-- vim.api.nvim_set_hl(0, "CursorLineNr", { fg = "#cdd6f4" }) -- bg = "#313244"
-- vim.api.nvim_set_hl(0, "LineNrAbove", { fg = "#eba0ac" })
-- vim.api.nvim_set_hl(0, "LineNrBelow", { fg = "#94e2d5" })
-- -- Set line number to be a bit darker
-- vim.api.nvim_set_hl(0, "Status_LineNr", { fg = "#6c7086" })
-- -- Color background the same as normal but color text light grey, use 'Vertical Line Extension' ⏐ unicode U+23D0
-- vim.api.nvim_set_hl(0, "Status_DivLine", { bg = "#1e1e2e", fg = "#313244" })
-- -- Set number and relativenumber options
-- vim.wo.number = true
-- vim.wo.relativenumber = true
-- -- Highlight current line, to hide and only use number highlight uncomment " set cursorlineopt
-- vim.wo.cursorline = true
-- -- Set signcolumn to always show and limit to 1 char so stuff doesn't move when LSP error occurs
-- vim.wo.signcolumn = "yes:1"
-- -- Configure statuscolumn
-- vim.o.statuscolumn = "%C%s%#Status_LineNr#%3.3l%* %-2.2r%#Status_DivLine#⏐%*"
