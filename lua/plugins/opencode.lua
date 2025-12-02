local function generate_commit_message()
    local handle = io.popen("git --no-pager diff --cached --no-color")
    local staged_changes = handle:read("*a")
    handle:close()
    
    if staged_changes == "" then
        vim.notify("No staged changes found", vim.log.levels.WARN)
        return
    end
    
    -- Remove newlines and limit length to avoid input issues
    staged_changes = staged_changes:gsub("\n", " "):sub(1, 1000)
    
    local prompt = "Generate a commit message using conventional commit format (feat:, fix:, refactor:, docs:, style:, test:, chore:). Keep under 72 characters, use imperative mood. Changes: " .. staged_changes .. " Reply with ONLY the commit message:"
    
    require('opencode').ask(prompt)
    vim.notify("Generate message with <leader>oc, then copy with <leader>oy and paste", vim.log.levels.INFO)
end

return {
	"NickvanDyke/opencode.nvim",
	dependencies = { "folke/snacks.nvim" },
	---@type require('opencode').Config
	opts = {
		port = 60601,
	},
    -- stylua: ignore
    keys = {
        { '<leader>ot', function() require('opencode').toggle() end,                           desc = 'Toggle embedded opencode', },
        { '<leader>oa', function() require('opencode').ask('@cursor: ') end,                   desc = 'Ask opencode',                 mode = 'n', },
        { '<leader>oa', function() require('opencode').ask('@selection: ') end,                desc = 'Ask opencode about selection', mode = 'v', },
        { '<leader>op', function() require('opencode').select_prompt() end,                    desc = 'Select prompt',                mode = { 'n', 'v', }, },
        { '<leader>on', function() require('opencode').command('session_new') end,             desc = 'New session', },
        { '<leader>oy', function() require('opencode').command('messages_copy') end,           desc = 'Copy last message', },
        { '<leader>oc', generate_commit_message,                                              desc = 'Generate commit message', },
        { '<S-C-u>',    function() require('opencode').command('messages_half_page_up') end,   desc = 'Scroll messages up', },
        { '<S-C-d>',    function() require('opencode').command('messages_half_page_down') end, desc = 'Scroll messages down', },
    },
}
