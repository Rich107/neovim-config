-- Shared list of globs identifying test files / test directories.
-- Used by test-aware grep and test-aware find_files pickers.

local M = {}

M.globs = {
	-- JS / TS
	"**/*.test.*",
	"**/*.spec.*",
	"**/__tests__/**",
	"**/cypress/**",
	"**/e2e/**",
	-- Python
	"**/test_*.py",
	"**/*_test.py",
	"**/conftest.py",
	-- Go
	"**/*_test.go",
	-- Ruby
	"**/*_spec.rb",
	-- C# / Java / Kotlin
	"**/*Test.cs",
	"**/*Tests.cs",
	"**/*Test.java",
	"**/*Tests.java",
	"**/*Test.kt",
	"**/*Tests.kt",
	-- Generic directories
	"**/tests/**",
	"**/test/**",
	"**/spec/**",
	"**/specs/**",
}

-- Returns rg args restricting results to test files: { "-g", g1, "-g", g2, ... }
function M.include_args()
	local args = {}
	for _, g in ipairs(M.globs) do
		table.insert(args, "-g")
		table.insert(args, g)
	end
	return args
end

-- Returns rg args excluding test files: { "-g", "!g1", "-g", "!g2", ... }
function M.exclude_args()
	local args = {}
	for _, g in ipairs(M.globs) do
		table.insert(args, "-g")
		table.insert(args, "!" .. g)
	end
	return args
end

return M
