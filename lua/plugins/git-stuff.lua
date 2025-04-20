return {
    { "tpope/vim-fugitive" },
    {
        "sindrets/diffview.nvim",
        cmd = { "DiffviewOpen", "DiffviewClose" },
        dependencies = { "nvim-lua/plenary.nvim" },
        config = function()
            require("diffview").setup()
            vim.keymap.set("n", "<leader>gdo", ":DiffviewOpen<CR>", {})
            vim.keymap.set("n", "<leader>gdc", ":DiffviewClose<CR>", {})
        end,
    },
    {
        "kdheepak/lazygit.nvim",
        cmd = {
            "LazyGit",
            "LazyGitConfig",
            "LazyGitCurrentFile",
            "LazyGitFilter",
            "LazyGitFilterCurrentFile",
        },
        -- optional for floating window border decoration
        dependencies = {
            "nvim-lua/plenary.nvim",
        },
        -- setting the keybinding for LazyGit with 'keys' is recommended in
        -- order to load the plugin when the command is run for the first time
        keys = {
            { "<leader>gg", "<cmd>LazyGit<cr>", desc = "Open lazy git" },
        },
    },
    {
        "lewis6991/gitsigns.nvim",
        config = function()
            require("gitsigns").setup()
            vim.keymap.set("n", "<leader>gsp", ":Gitsigns preview_hunk<CR>", {})
            vim.keymap.set("n", "<leader>gst", ":Gitsigns toggle_current_line_blame<CR>", {})
            vim.keymap.set("n", "<leader>gsb", ":Gitsigns blame<CR>", {})
        end,
    },
}
