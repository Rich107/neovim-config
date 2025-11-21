-- Simple large file detection and handling
local M = {}

-- Configuration
M.line_limit = 4000  -- Files larger than this will trigger performance mode

-- Function to check if a file is considered large
function M.is_large_file(bufnr)
    bufnr = bufnr or vim.api.nvim_get_current_buf()
    local line_count = vim.api.nvim_buf_line_count(bufnr)
    return line_count > M.line_limit
end

-- Apply performance settings to large files
function M.setup()
    -- Create autogroup for large file detection
    local augroup = vim.api.nvim_create_augroup("LargeFile", { clear = true })
    
    -- Add autocommand to detect large files on load
    vim.api.nvim_create_autocmd({"BufReadPre", "BufNewFile"}, {
        group = augroup,
        callback = function(args)
            local path = vim.api.nvim_buf_get_name(args.buf)
            if vim.fn.getfsize(path) > 1024 * 1024 then
                -- File size > 1MB, early detection
                vim.b[args.buf].large_file = true
                vim.schedule(function()
                    vim.notify("Large file detected, performance optimizations applied", vim.log.levels.INFO)
                end)
            end
        end
    })
    
    -- Main detection - check line count after file is loaded
    vim.api.nvim_create_autocmd({"BufReadPost", "BufNewFile"}, {
        group = augroup,
        callback = function(args)
            if vim.b[args.buf].large_file or M.is_large_file(args.buf) then
                -- Disable treesitter
                pcall(vim.cmd, "TSBufDisable highlight")
                
                -- Switch to manual folding
                vim.opt_local.foldmethod = "manual"
                
                -- Disable relative line numbers
                vim.opt_local.relativenumber = false
                
                -- Store flag in buffer
                vim.b[args.buf].large_file = true
                
                -- Notify the user
                vim.schedule(function()
                    vim.notify("Large file detected (> " .. M.line_limit .. " lines). Some features disabled.", 
                        vim.log.levels.INFO)
                end)
            end
        end
    })
end

return M