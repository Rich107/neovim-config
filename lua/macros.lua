local function log_variable()
	-- Use feedkeys to send the key sequence
	vim.api.nvim_feedkeys(
		vim.api.nvim_replace_termcodes('yoconsole.log("<Esc>pa:", <Esc>pa);<Esc>', true, true, true),
		"n",
		true
	)
end

vim.api.nvim_set_keymap("v", "<leader>L", "", {
	noremap = true,
	silent = true,
	callback = log_variable,
	desc = "Log variable to console for js",
})

-- Append a unique UUID (uuid4().hex style: 32 lowercase hex chars, no dashes)
-- to the end of every visually-selected line, with an optional prefix you type.
-- Whatever you enter at the prompt is inserted before the UUID, so include any
-- separator yourself, e.g. "order-" -> "...existing lineorder-<uuid>".
local function append_uuid_to_lines()
	-- Capture the line range while still in visual mode.
	local start_line = vim.fn.line("v")
	local end_line = vim.fn.line(".")
	if start_line > end_line then
		start_line, end_line = end_line, start_line
	end

	local prefix = vim.fn.input("Prefix (before uuid): ")
	local count = end_line - start_line + 1

	-- Generate all UUIDs in a single shell call instead of one process per line.
	local out = vim.fn.system(string.format("for _ in $(seq %d); do uuidgen; done", count))
	local uuids = {}
	for u in out:gmatch("[^\r\n]+") do
		table.insert(uuids, (u:gsub("%-", "")):lower())
	end

	local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)
	for i, line in ipairs(lines) do
		lines[i] = line .. prefix .. (uuids[i] or "")
	end
	vim.api.nvim_buf_set_lines(0, start_line - 1, end_line, false, lines)
end

vim.api.nvim_set_keymap("v", "<leader>u", "", {
	noremap = true,
	silent = true,
	callback = append_uuid_to_lines,
	desc = "Append a unique UUID to each selected line (with optional prefix)",
})
