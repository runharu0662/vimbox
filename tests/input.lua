vim.opt.rtp:prepend(vim.fn.getcwd())
local temp = vim.fn.tempname()
local stdpath = vim.fn.stdpath
vim.fn.stdpath = function(kind)
	return kind == "data" and temp or stdpath(kind)
end

require("vimbox").open()
local buf = vim.api.nvim_get_current_buf()
assert(not vim.wo.wrap)
-- Simulate an editor plugin attaching after Vimbox installs its mappings.
local conflict = vim.api.nvim_create_autocmd("InsertEnter", {
	buffer = buf,
	callback = function()
		vim.keymap.set("i", "<CR>", "<CR>", { buffer = buf })
	end,
})
vim.api.nvim_exec_autocmds("InsertEnter", { buffer = buf })
assert(vim.wait(100, function()
	return vim.fn.maparg("<CR>", "i", false, true).desc == "Enqueue item"
end))
local keys = vim.api.nvim_replace_termcodes("iCaptured text<CR><Esc>", true, false, true)
vim.api.nvim_del_autocmd(conflict)
vim.api.nvim_feedkeys(keys, "xt", false)
assert(require("vimbox.queue").list()[1] == "Captured text")
assert(vim.api.nvim_buf_line_count(buf) == 1)
assert(vim.api.nvim_buf_get_lines(buf, 0, -1, false)[1] == "")
vim.fn.stdpath = stdpath
vim.fn.delete(temp, "rf")
print("PASS: insert Enter enqueues without newline after mapping conflict; input does not wrap")
vim.cmd("qa!")
