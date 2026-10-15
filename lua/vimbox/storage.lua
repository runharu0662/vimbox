local M = {}
local path = vim.fn.stdpath("data") .. "/vimbox_queue.json"

function M.save(items)
	local ok, err = pcall(function()
		vim.fn.mkdir(vim.fn.fnamemodify(path, ":h"), "p")
		local temp = path .. "." .. vim.fn.getpid() .. ".tmp"
		if vim.fn.writefile({ vim.json.encode(items) }, temp) ~= 0 then
			error("could not write queue")
		end
		if vim.fn.rename(temp, path) ~= 0 then error("could not replace queue") end
	end)
	if not ok then vim.notify("Vimbox: save failed: " .. tostring(err), vim.log.levels.ERROR) end
	return ok
end

function M.load()
	if vim.fn.filereadable(path) == 0 then return {} end
	local ok, result = pcall(function()
		local items = vim.json.decode(table.concat(vim.fn.readfile(path), "\n"))
		assert(type(items) == "table" and vim.islist(items), "expected a list")
		for _, item in ipairs(items) do assert(type(item) == "string", "expected text items") end
		return items
	end)
	if not ok then
		error("Vimbox: cannot read saved queue (file preserved): " .. tostring(result))
	end
	return result
end

return M
