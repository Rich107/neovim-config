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
    },
}
