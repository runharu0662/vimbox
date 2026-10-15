local M = {}
local storage = require("vimbox.storage")
local items = storage.load()

function M.list()
	return vim.deepcopy(items)
end

function M.push(item)
	if type(item) ~= "string" or vim.trim(item) == "" then return false end
	local next_items = M.list()
	table.insert(next_items, vim.trim(item))
	if not storage.save(next_items) then return false end
	items = next_items
	return true
end

function M.rename(index, text)
	if type(index) ~= "number" or index % 1 ~= 0 or not items[index]
		or type(text) ~= "string" or vim.trim(text) == "" then return false end
	local next_items = M.list()
	next_items[index] = vim.trim(text)
	if not storage.save(next_items) then return false end
	items = next_items
	return true
end

function M.pop()
	if #items == 0 then return nil end
	local next_items = M.list()
	local item = table.remove(next_items, 1)
	if not storage.save(next_items) then return nil end
	items = next_items
	return item
end

return M
