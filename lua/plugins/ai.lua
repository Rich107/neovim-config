return {
    {
        "CopilotC-Nvim/CopilotChat.nvim",
        dependencies = {
            {
                "zbirenbaum/copilot.lua",
                cmd = "Copilot",
                build = ":Copilot auth",
                config = function()
                    require("copilot").setup({
                        suggestion = { enabled = true },
                        panel = { enabled = true },
                    })
                end,
            },
            {
                "nvim-lua/plenary.nvim",
                branch = "master",
            },
        },
        build = "make tiktoken",
        opts = {
            mappings = {
                reset = {
                    normal = "<Leader>rrr",
                    insert = false,
                },
                complete = {
                    insert = false,
                },
            },
        },
    },
}
