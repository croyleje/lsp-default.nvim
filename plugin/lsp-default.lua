local function setup_server(input)
	local opts = {}
	if input.bang then
		opts.root_dir = function()
			return vim.fn.get_cwd()
		end
	end

	require("lsp-default").use(input.fargs, opts)
end

local function complete_server()
	return require("lsp-default.installer").get_servers()
end

vim.api.nvim_create_user_command("LspDefaultSetupServers", setup_server, {
	bang = true,
	nargs = "*",
	complete = complete_server,
})
