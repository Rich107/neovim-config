return {
    {
        "nvim-treesitter/nvim-treesitter",
        build = ":TSUpdate",
        event = { "BufReadPost", "BufNewFile" },
        config = function()
            -- Setup treesitter configs with default settings
            require("nvim-treesitter.configs").setup({
                auto_install = true,
                highlight = { 
                    enable = true,
                    -- Disable treesitter highlight for large files
                    disable = function(_, buf)
                        local max_filesize = 4000 * 1024 -- 4000 KB or roughly 4000 lines
                        local ok, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(buf))
                        if ok and stats and stats.size > max_filesize then
                            return true
                        end
                        
                        -- Also disable based on line count
                        local line_count = vim.api.nvim_buf_line_count(buf)
                        return line_count > 4000
                    end,
                },
                indent = { enable = true },
                ensure_installed = {
                    "vue",
                    "markdown",
                    "lua",
                    "query",
                    "sql",
                    "scss",
                    "css",
                    "html",
                    "javascript",
                    "python",
                    "typescript",
                },
                -- Enable nvim-biscuits via the nvim-treesitter module system
                nvim_biscuits = { enable = true },
                -- Configuring the textobjects module
                textobjects = {
                    select = {
                        enable = true,
                        lookahead = true,
                        keymaps = {
                            -- Function selection (inner and outer)
                            ["af"] = "@function.outer",
                            ["if"] = "@function.inner",
                            -- Class selection (inner and outer)
                            ["ac"] = "@class.outer",
                            ["ic"] = "@class.inner",
                            ["ai"] = "@indent.outer", -- Select around the indentation level
                            ["ii"] = "@indent.inner", -- Select inside the indentation level
                        },
                    },
                    move = {
                        enable = true,
                        set_jumps = true,
                        goto_next_start = {
                            ["]f"] = "@function.outer",
                        },
                        goto_next_end = {
                            ["]F"] = "@function.outer",
                        },
                        goto_previous_start = {
                            ["[f"] = "@function.outer",
                        },
                        goto_previous_end = {
                            ["[F"] = "@function.outer",
                        },
                    },
                    -- swap = {
                    --     enable = true,
                    --     swap_next = {
                    --         ["<leader>a"] = "@parameter.inner",
                    --     },
                    --     swap_previous = {
                    --         ["<leader>A"] = "@parameter.inner",
                    --     },
                    -- },
                },
            })
        end,
    },
    {
        "nvim-treesitter/nvim-treesitter-textobjects",
        after = "nvim-treesitter",
    },
    -- nvim-biscuits: show end-of-scope context via treesitter
    {
        "code-biscuits/nvim-biscuits",
        event = { "BufReadPost", "BufNewFile" },
        dependencies = { "nvim-treesitter/nvim-treesitter" },
        config = function()
            -- Basic setup: show on start, we will control visibility by mode
            local biscuits = require("nvim-biscuits")
            biscuits.setup({
                -- keep defaults; show_on_start defaults true; we rely on TS module integration
            })

            -- Ensure the treesitter module is enabled even if TS was configured earlier
            require("nvim-treesitter.configs").setup({ nvim_biscuits = { enable = true } })
            -- Attach to the current buffer immediately
            pcall(biscuits.BufferAttach)

            -- Hide biscuits while in insert mode; show in normal mode
            local ts_parsers = require("nvim-treesitter.parsers")

            local function redraw_current()
                local bufnr = vim.api.nvim_get_current_buf()
                local lang = ts_parsers.get_buf_lang(bufnr)
                if not lang or lang == "" then return end
                lang = lang:gsub("-", "")
                biscuits.decorate_nodes(bufnr, lang)
            end

            vim.api.nvim_create_autocmd("InsertEnter", {
                group = vim.api.nvim_create_augroup("BiscuitsModeVisibility", { clear = true }),
                callback = function()
                    biscuits.should_render_biscuits = false
                    redraw_current()
                end,
                desc = "Hide nvim-biscuits in insert mode",
            })

            vim.api.nvim_create_autocmd("InsertLeave", {
                group = vim.api.nvim_create_augroup("BiscuitsModeVisibility", { clear = false }),
                callback = function()
                    biscuits.should_render_biscuits = true
                    redraw_current()
                end,
                desc = "Show nvim-biscuits when leaving insert mode",
            })
        end,
    },
}
