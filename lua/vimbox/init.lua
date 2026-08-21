local M = {}

local queue = require("vimbox.queue")

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

	vim.keymap.set("n", "<CR>", function()
		local lines = vim.api.nvim_buf_get_lines(buf, 0, 1, false)
		local text = lines[1]
		queue.push(text)
		vim.notify("Vimbox: " .. text)
	end, { buffer = buf })
end

return M
