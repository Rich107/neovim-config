-- ~/.config/nvim/lua/plugins/spellcheck.lua

local spellcheck_filetypes = { "gitcommit", "markdown", "text" }
local spellcheck_languages = { "en_gb" }

-- Default key mappings (can be customized by the user)
local key_mappings = {
	next_misspelled = "<leader>zn",
	prev_misspelled = "<leader>zp",
	correct_misspelled = "<leader>zc",
	add_word = "<leader>za",
	mark_wrong = "<leader>zd",
	toggle_spell = "<leader>zs",
}

-- Enable spellcheck for approved file types
vim.api.nvim_create_autocmd("FileType", {
	pattern = spellcheck_filetypes,
	callback = function()
		vim.opt_local.spell = true
		vim.opt_local.spelllang = table.concat(spellcheck_languages, ",")

		-- Navigate misspellings
		vim.api.nvim_buf_set_keymap(0, "n", key_mappings.next_misspelled, "]s", { noremap = true, silent = true })
		vim.api.nvim_buf_set_keymap(0, "n", key_mappings.prev_misspelled, "[s", { noremap = true, silent = true })

		-- Correct misspelling
		vim.api.nvim_buf_set_keymap(
			0,
			"n",
			key_mappings.correct_misspelled,
			"z=",
			{ desc = "Change word", noremap = true, silent = true }
		)

		-- Add word to spell file
		vim.api.nvim_buf_set_keymap(
			0,
			"n",
			key_mappings.add_word,
			"zg",
			{ desc = "Add word", noremap = true, silent = true }
		)

		-- Mark word as wrong
		vim.api.nvim_buf_set_keymap(
			0,
			"n",
			key_mappings.mark_wrong,
			"zw",
			{ desc = "Mark wrong word", noremap = true, silent = true }
		)

		-- Toggle spell checking
		vim.api.nvim_buf_set_keymap(
			0,
			"n",
			key_mappings.toggle_spell,
			":set spell!<CR>",
			{ noremap = true, silent = true }
		)
	end,
})

return {}
