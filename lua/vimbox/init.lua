local M = {}

function M.open()
	local buf = vim.api.nvim_create_buf(false, true)
	local config = {
		relative = "editor",
		width = 40,
		height = 10,
		row = 3,
		col = 5,
		style = "minimal",
		border = "rounded",
	}
	local win = vim.api.nvim_open_win(buf, true, config)
	vim.keymap.set("n", "q", function()
		vim.api.nvim_win_close(win, true)
	end, { buffer = buf })
end

return M
