local M = {}

local path = vim.fn.stdpath("data") .. "/vimbox_queue.json"

function M.save(items)
	local json = vim.json.encode(items)
	vim.fn.writefile({ json }, path)
end

function M.load()
	if vim.fn.filereadable(path) == 0 then
		return {}
	end

	local lines = vim.fn.readfile(path)
	return vim.json.decode(lines[1])
end

return M
