vim.api.nvim_create_user_command("VimboxOpen", function()
	require("vimbox").open()
end, {})

vim.api.nvim_create_user_command("VimboxPop", function()
	require("vimbox").pop()
end, {})
