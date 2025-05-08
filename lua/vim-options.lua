vim.cmd("set expandtab")
vim.cmd("set tabstop=4")
vim.cmd("set softtabstop=4")
vim.cmd("set shiftwidth=4")
vim.g.mapleader = " "
vim.g.background = "light"

local keymap = vim.keymap -- for conciseness

vim.o.wrap = false

vim.diagnostic.config({
    virtual_text = true,
})

vim.opt.swapfile = false

-- Makes breakpoingts clearer
vim.fn.sign_define("DapBreakpoint", {
    text = "🛑",
    texthl = "",
    linehl = "",
    numhl = "",
})

vim.fn.sign_define("DapStopped", {
    text = "🫠️",
    texthl = "",
    linehl = "",
    numhl = "",
})
-- This stops unreachable from being greyed out
-- pyright is not that great figuring out when to do this.
-- vim.api.nvim_set_hl(0, "@lsp.type.unreachable", { link = "Normal" })

-- This allows copy paste to work in ssh connections:
local osc52 = require("vim.ui.clipboard.osc52")

vim.api.nvim_create_autocmd({ "BufEnter", "TextChanged", "InsertLeave" }, {
    pattern = "*.vue",
    callback = function()
        local html_tags = {
            "html",
            "head",
            "title",
            "base",
            "link",
            "meta",
            "style",
            "script",
            "noscript",
            "body",
            "section",
            "nav",
            "article",
            "aside",
            "h1",
            "h2",
            "h3",
            "h4",
            "h5",
            "h6",
            "header",
            "footer",
            "address",
            "main",
            "p",
            "hr",
            "pre",
            "blockquote",
            "ol",
            "ul",
            "li",
            "dl",
            "dt",
            "dd",
            "figure",
            "figcaption",
            "div",
            "a",
            "em",
            "strong",
            "small",
            "s",
            "cite",
            "q",
            "dfn",
            "abbr",
            "data",
            "time",
            "code",
            "var",
            "samp",
            "kbd",
            "sub",
            "sup",
            "i",
            "b",
            "u",
            "mark",
            "ruby",
            "rt",
            "rp",
            "bdi",
            "bdo",
            "span",
            "br",
            "wbr",
            "ins",
            "del",
            "img",
            "iframe",
            "embed",
            "object",
            "param",
            "video",
            "audio",
            "source",
            "track",
            "canvas",
            "map",
            "area",
            "svg",
            "math",
            "table",
            "caption",
            "colgroup",
            "col",
            "tbody",
            "thead",
            "tfoot",
            "tr",
            "td",
            "th",
            "form",
            "fieldset",
            "legend",
            "label",
            "input",
            "button",
            "select",
            "datalist",
            "optgroup",
            "option",
            "textarea",
            "output",
            "progress",
            "meter",
            "details",
            "summary",
            "dialog",
            "script",
            "template",
            "slot",
        }
        local html_tag_lookup = {}
        for _, tag in ipairs(html_tags) do
            html_tag_lookup[tag] = true
        end

        local bufnr = vim.api.nvim_get_current_buf()
        local ns = vim.api.nvim_create_namespace("custom-tag-highlighter")
        vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)

        local parser = vim.treesitter.get_parser(bufnr, "vue")
        local tree = parser:parse()[1]
        local root = tree:root()

        local query = vim.treesitter.query.parse(
            "vue",
            [[
                  (element
                  (start_tag (tag_name) @tag_name)
                  (end_tag (tag_name) @closing_tag_name)?)
            ]]
        )
        for id, node in query:iter_captures(root, bufnr, 0, -1) do
            local capture_name = query.captures[id]
            local tag = vim.treesitter.get_node_text(node, bufnr)

            if not html_tag_lookup[tag] and (capture_name == "tag_name" or capture_name == "closing_tag_name") then
                local row, col, _, end_col = node:range()
                vim.api.nvim_buf_add_highlight(bufnr, ns, "CustomTagName", row, col, end_col)
            end
        end
    end,
})

vim.api.nvim_set_hl(0, "CustomTagName", { fg = "#f48a9f", bold = true })

-- This allows copy paste to work in ssh connections:
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
keymap.set("n", "<leader>cpc", "<cmd>CopilotChatToggle<CR>", { desc = "Toggles AI Chat Window" })

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

vim.keymap.set("n", "<leader>gdo", "<cmd>DiffviewOpen<CR>", { silent = true, desc = "Diff Split Open" })
vim.keymap.set("n", "<leader>gdc", "<cmd>DiffviewClose<CR>", { silent = true, desc = "Diff Split Close" })
vim.keymap.set("n", "<leader>gds", "<cmd>Gdiffsplit!<CR>", { silent = true, desc = "Git Diff Split" })

vim.api.nvim_set_keymap("n", "<C-d>", "<C-d>zz", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "<C-u>", "<C-u>zz", { noremap = true, silent = true })

vim.api.nvim_set_hl(0, "LineNrAbove", { fg = "#51B3EC", bold = true })
vim.api.nvim_set_hl(0, "LineNr", { fg = "white", bold = true })
vim.api.nvim_set_hl(0, "LineNrBelow", { fg = "#FB508F", bold = true })

vim.wo.cursorline = true
vim.api.nvim_set_hl(0, "CursorLine", { bg = "#f0f0f0" })                -- Adjust color to suit your theme
vim.api.nvim_set_hl(0, "CursorLineNr", { fg = "#000000", bold = true }) -- Make line number bold and visible

vim.api.nvim_set_keymap("n", "<leader>Log", ":lua log_variable()<CR>", { noremap = true, silent = true })
