return {
    "NeogitOrg/neogit",
    dependencies = {
        "nvim-lua/plenary.nvim",
        "sindrets/diffview.nvim",
        "nvim-telescope/telescope.nvim",
    },
    cmd = "Neogit",
    keys = {
        { "<leader>gn", "<cmd>Neogit<cr>", desc = "Neogit" },
    },
    opts = {
        integrations = {
            diffview = true,
            telescope = true,
        },
        commit_editor = {
            show_staged_diff = true,
        },
        signs = {
            hunk = { "", "" },
            item = { ">", "v" },
            section = { ">", "v" },
        },
        process_spinner = true,
        graph_style = "unicode",
    },
}
