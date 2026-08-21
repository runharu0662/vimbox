local M = {}

local items = {}

function M.push(item)
	table.insert(items, item)
end

function M.pop()
	return table.remove(items, 1)
end

return M
