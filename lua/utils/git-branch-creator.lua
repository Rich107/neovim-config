-- Git Branch Creator Module
-- A utility to create a new branch from the latest production/main/master

local M = {}

-- Function to find the base branch (production, main, or master)
local function find_base_branch()
    local base_branches = {"production", "main", "master"}
    -- Check if we're in a git repository
    local is_git_repo = vim.fn.system("git rev-parse --is-inside-work-tree 2>/dev/null"):match("true")
    if not is_git_repo then
        vim.notify("Not in a git repository", vim.log.levels.ERROR)
        return nil
    end
    -- Get all available branches
    local branches = {}
    local handle = io.popen("git branch -a 2>/dev/null")
    if handle then
        for line in handle:lines() do
            -- Remove leading whitespace and '*' for current branch
            local branch = line:gsub("^%s*%*?%s*", "")
            -- Remove 'remotes/origin/' prefix for clarity
            branch = branch:gsub("^remotes/origin/", "")
            table.insert(branches, branch)
        end
        handle:close()
    end
    -- Look for base branches in order of preference
    for _, base in ipairs(base_branches) do
        for _, branch in ipairs(branches) do
            if branch == base then
                return base
            end
        end
    end
    vim.notify("No base branch (production/main/master) found", vim.log.levels.ERROR)
    return nil
end

-- Function to create a new branch from the base branch
local function create_branch_from_base(branch_name)
    if branch_name == nil or branch_name == "" then
        vim.notify("Branch name cannot be empty", vim.log.levels.ERROR)
        return false
    end
    -- Find the base branch
    local base_branch = find_base_branch()
    if base_branch == nil then
        return false
    end
    vim.notify("Creating branch '" .. branch_name .. "' from '" .. base_branch .. "'", vim.log.levels.INFO)
    -- Pull latest changes from the base branch
    local pull_cmd = "git fetch origin " .. base_branch .. " && git checkout " .. base_branch .. " && git pull origin " .. base_branch
    local pull_result = vim.fn.system(pull_cmd)
    if vim.v.shell_error ~= 0 then
        vim.notify("Failed to update base branch: " .. pull_result, vim.log.levels.ERROR)
        return false
    end
    -- Create and checkout the new branch
    local create_cmd = "git checkout -b " .. branch_name
    local create_result = vim.fn.system(create_cmd)
    if vim.v.shell_error ~= 0 then
        vim.notify("Failed to create new branch: " .. create_result, vim.log.levels.ERROR)
        return false
    end
    vim.notify("Successfully created and switched to branch '" .. branch_name .. "'", vim.log.levels.INFO)
    return true
end

-- Function to show the input prompt and create the branch
function M.show_branch_creator()
    -- Check if we're in a git repository
    local is_git_repo = vim.fn.system("git rev-parse --is-inside-work-tree 2>/dev/null"):match("true")
    if not is_git_repo then
        vim.notify("Not in a git repository", vim.log.levels.ERROR)
        return
    end
    -- Show input prompt for the branch name
    vim.ui.input(
        { prompt = "New branch name: " },
        function(branch_name)
            if branch_name and branch_name ~= "" then
                create_branch_from_base(branch_name)
            end
        end
    )
end

return M