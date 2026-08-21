local M = {}

local storage = require("vimbox.storage")
local items = storage.load()

function M.push(item)
	table.insert(items, item)
	storage.save(items)
end

function M.pop()
	local item = table.remove(items, 1)
	storage.save(items)
	return item
end

return M
