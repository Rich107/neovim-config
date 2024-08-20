return {
    {
        "catppuccin/nvim",
        lazy = false,
        name = "catppuccin",
        priority = 1000,
        config = function()
            -- Set up the colorscheme
            vim.cmd.colorscheme("catppuccin-mocha")

            -- Set the separator color to white
            vim.api.nvim_set_hl(0, "WinSeparator", { fg = "#ffffff", bg = "None", ctermfg = "white", ctermbg = "None" })

            -- Apply the highlight group to window separators
            vim.o.winhighlight = "VertSplit:WinSeparator"
        end,
    },
}
