vim.api.nvim_create_user_command("VimboxOpen", function()
	require("vimbox").open()
end, {})
