local M = {}
local queue = require("vimbox.queue")
local state = {}

local function close()
	for _, key in ipairs({ "input_win", "list_win" }) do
		local win = state[key]
		if win and vim.api.nvim_win_is_valid(win) then
			vim.api.nvim_win_close(win, true)
		end
	end
	state = {}
end

local function render()
	if not state.list_buf or not vim.api.nvim_buf_is_valid(state.list_buf) then
		return
	end
	local items = queue.list()
	local lines = {}
	if #items == 0 then
		lines = { "", "  Inbox is clear", "  Add a thought in the field below." }
	else
		for i, item in ipairs(items) do
			lines[#lines + 1] = string.format("  %s %02d  %s", i == 1 and "▶" or "·", i, item)
		end
	end
	vim.bo[state.list_buf].modifiable = true
	vim.api.nvim_buf_set_lines(state.list_buf, 0, -1, false, lines)
	vim.bo[state.list_buf].modifiable = false
	vim.api.nvim_win_set_config(state.list_win, {
		title = string.format(" Vimbox · %d pending ", #items), title_pos = "center",
	})
	vim.api.nvim_buf_clear_namespace(state.list_buf, state.ns, 0, -1)
	if #items > 0 then
		vim.api.nvim_buf_add_highlight(state.list_buf, state.ns, "DiagnosticOk", 0, 0, -1)
	else
		vim.api.nvim_buf_add_highlight(state.list_buf, state.ns, "Comment", 1, 0, -1)
		vim.api.nvim_buf_add_highlight(state.list_buf, state.ns, "Comment", 2, 0, -1)
	end
end

local function finish_edit()
	state.edit_index = nil
	vim.api.nvim_buf_set_lines(state.input_buf, 0, -1, false, state.draft or { "" })
	state.draft = nil
	vim.api.nvim_win_set_config(state.input_win, {
		title = " Capture ", footer = " Enter: enqueue · Tab: inbox ",
	})
	vim.cmd.stopinsert()
	vim.api.nvim_set_current_win(state.list_win)
end

local function rename()
	local index = vim.api.nvim_win_get_cursor(state.list_win)[1]
	local item = queue.list()[index]
	if not item then return end
	if not state.edit_index then
		state.draft = vim.api.nvim_buf_get_lines(state.input_buf, 0, -1, false)
	end
	state.edit_index = index
	vim.api.nvim_buf_set_lines(state.input_buf, 0, -1, false, { item })
	vim.api.nvim_win_set_config(state.input_win, {
		title = string.format(" Rename #%02d ", index),
		footer = " Enter: save · Esc: cancel ",
	})
	vim.api.nvim_set_current_win(state.input_win)
	vim.api.nvim_win_set_cursor(state.input_win, { 1, #item })
	vim.cmd.startinsert({ bang = true })
end

local function submit()
	local lines = vim.api.nvim_buf_get_lines(state.input_buf, 0, -1, false)
	local text = vim.trim(table.concat(lines, " "))
	if text == "" then
		return
	end
	if state.edit_index then
		if queue.rename(state.edit_index, text) then
			finish_edit()
			render()
		end
		return
	end
	if not queue.push(text) then
		return
	end
	vim.api.nvim_buf_set_lines(state.input_buf, 0, -1, false, { "" })
	render()
end

local function complete()
	if state.edit_index then
		vim.notify("Vimbox: save or cancel the edit first", vim.log.levels.INFO)
		return
	end
	local item = queue.pop()
	render()
	if item then
		vim.notify("Vimbox: done · " .. item)
	end
end

function M.open()
	if state.input_win and vim.api.nvim_win_is_valid(state.input_win)
		and state.list_win and vim.api.nvim_win_is_valid(state.list_win) then
		vim.api.nvim_set_current_win(state.input_win)
		return
	end
	close()
	if vim.o.columns < 30 or vim.o.lines < 14 then
		vim.notify("Vimbox: enlarge the editor to at least 30 columns × 14 lines", vim.log.levels.WARN)
		return
	end
	local width = math.min(76, vim.o.columns - 6)
	local height = math.min(16, vim.o.lines - 10)
	local row = math.floor((vim.o.lines - height - 7) / 2)
	local col = math.floor((vim.o.columns - width) / 2)
	state.ns = vim.api.nvim_create_namespace("vimbox")
	state.list_buf = vim.api.nvim_create_buf(false, true)
	state.input_buf = vim.api.nvim_create_buf(false, true)
	state.list_win = vim.api.nvim_open_win(state.list_buf, true, {
		relative = "editor", width = width, height = height, row = row, col = col,
		style = "minimal", border = "rounded", title = " Vimbox ", title_pos = "center",
		footer = " d: done oldest · r: rename · i: add · q: close ", footer_pos = "center",
	})
	state.input_win = vim.api.nvim_open_win(state.input_buf, true, {
		relative = "editor", width = width, height = 1, row = row + height + 2, col = col,
		style = "minimal", border = "rounded", title = " Capture ", title_pos = "left",
		footer = " Enter: enqueue · Tab: inbox ", footer_pos = "center",
	})
	for _, buf in ipairs({ state.list_buf, state.input_buf }) do
		vim.bo[buf].bufhidden = "wipe"
		vim.bo[buf].filetype = "vimbox"
		vim.keymap.set("n", "q", close, { buffer = buf, desc = "Close Vimbox" })
		vim.keymap.set({ "n", "i" }, "<C-c>", function()
			vim.cmd.stopinsert()
			close()
		end, { buffer = buf, desc = "Close Vimbox" })
	end
	for _, win in ipairs({ state.list_win, state.input_win }) do
		vim.wo[win].winhighlight = "Normal:NormalFloat,FloatBorder:FloatBorder,FloatTitle:Title"
	end
	vim.wo[state.list_win].cursorline = true
	vim.wo[state.list_win].wrap = true
	vim.keymap.set({ "n", "i" }, "<CR>", submit, { buffer = state.input_buf, desc = "Enqueue item" })
	vim.keymap.set({ "n", "i" }, "<Esc>", function()
		vim.cmd.stopinsert()
		if state.edit_index then finish_edit() end
	end, { buffer = state.input_buf, desc = "Cancel edit or leave insert mode" })
	vim.keymap.set({ "n", "i" }, "<Tab>", function()
		vim.cmd.stopinsert()
		vim.api.nvim_set_current_win(state.list_win)
	end, { buffer = state.input_buf, desc = "Focus inbox" })
	vim.keymap.set("n", "i", function()
		vim.api.nvim_set_current_win(state.input_win)
		vim.cmd.startinsert()
	end, { buffer = state.list_buf, desc = "Capture item" })
	vim.keymap.set("n", "d", complete, { buffer = state.list_buf, desc = "Complete oldest item" })
	vim.keymap.set("n", "r", rename, { buffer = state.list_buf, desc = "Rename selected item" })
	vim.keymap.set("n", "e", rename, { buffer = state.list_buf, desc = "Edit selected item" })
	local wins = { state.list_win, state.input_win }
	vim.api.nvim_create_autocmd("WinClosed", {
		pattern = { tostring(wins[1]), tostring(wins[2]) },
		once = true,
		callback = function()
			vim.schedule(function()
				if state.list_win == wins[1] then close() end
			end)
		end,
	})
	render()
	vim.cmd.startinsert()
end

return M
