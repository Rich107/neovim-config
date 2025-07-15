return {
    {
        "epwalsh/obsidian.nvim",
        version = "*",
        ft = "markdown",
        dependencies = {
            "nvim-lua/plenary.nvim",
        },
        opts = {
            workspaces = {
                {
                    name = "Personal",
                    path = "~/Documents/Obsidian Vaults/Personal",
                },
                {
                    name = "work",
                    path = "~/Documents/Obsidian Vaults/Legl",
                },
            },
        },
    },
}
