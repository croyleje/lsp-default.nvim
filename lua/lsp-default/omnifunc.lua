local M = {}
local s = {}
local group = "lsp_default_completion"
local pattern = "[[:keyword:]]"

local match = vim.fn.match
local pumvisible = vim.fn.pumvisible
local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd

local t = function(k)
	return vim.api.nvim_replace_termcodes(k, true, false, true)
end

local key = {
	omni = "<C-x><C-o>",
	buffer = "<C-x><C-n>",
	next_item = "<Down>",
	prev_item = "<Up>",
	confirm = "<C-y>",
	abort = "<C-e>",
	tab = "<Tab>",
}

local omni_code = t(key.omni)
local buffer_code = t(key.buffer)

function M.setup(user_opts)
	if type(user_opts) ~= "table" then
		user_opts = {}
	end

	local defaults = {
		-- completion modes
		tabcomplete = false,
		autocomplete = false,
		trigger = nil,
		use_fallback = false,

		-- custom behavior
		verbose = false,
		preselect = true,
		keyword_pattern = nil,
		select_behavior = "select",
		update_on_delete = false,

		mapping = {
			confirm = nil,
			abort = nil,
			next_item = nil,
			prev_item = nil,
		},
	}

	local opts = vim.tbl_deep_extend("force", defaults, user_opts)

	local id = augroup("lsp_default_omnifunc", { clear = true })
	local mapping = opts.mapping

	if opts.preselect == false then
		vim.opt.completeopt:append("noselect")
	end

	if opts.verbose == false then
		vim.opt.shortmess:append("c")
	end

	if type(opts.keyword_pattern) == "string" then
		pattern = opts.keyword_pattern
	end

	if opts.select_behavior == "select" then
		vim.opt.completeopt:append("noinsert")
	elseif opts.select_behavior == "insert" then
		vim.opt.completeopt:remove("noinsert")
		key.next_item = "<C-n>"
		key.prev_item = "<C-p>"
	end

	vim.opt.completeopt:remove("preview")
	vim.opt.completeopt:append("menu")
	vim.opt.completeopt:append("menuone")

	s.keymap(mapping.next_item, key.next_item)
	s.keymap(mapping.prev_item, key.prev_item)
	s.keymap(mapping.abort, key.abort)

	if type(mapping.confirm) == "string" then
		local confirm = string.lower(mapping.confirm)
		if not vim.tbl_contains({ "<enter>", "<cr>" }, confirm) then
			s.keymap(mapping.confirm, key.confirm)
		end
	end

	local set_autocomplete = opts.autocomplete
	local set_tabcomplete = opts.tabcomplete
	local set_toggle = opts.trigger
	local map_backspace = opts.update_on_delete

	if set_autocomplete then
		vim.opt.completeopt:append("noinsert")
	end

	if opts.use_fallback then
		if set_autocomplete then
			M.autocomplete_fallback()
		end

		if set_tabcomplete then
			M.tab_complete_fallback()
		end

		if set_toggle then
			M.toggle_menu_fallback(set_toggle)
		end
	end

	autocmd("LspAttach", {
		group = id,
		desc = "setup LSP omnifunc completion",
		callback = function(event)
			if set_autocomplete then
				M.autocomplete(event.buf)
			end

			if set_tabcomplete then
				M.tab_complete(event.buf)
			end

			if set_toggle then
				M.toggle_menu(set_toggle, event.buf)
			end

			if map_backspace then
				s.backspace(event.buf)
			end
		end,
	})
end

function M.autocomplete(buffer)
	pcall(vim.api.nvim_clear_autocmds, { group = group, buffer = buffer })
	augroup(group, { clear = false })

	autocmd("InsertCharPre", {
		buffer = buffer,
		group = group,
		desc = "Autocomplete using the LSP omnifunc",
		callback = s.try_complete,
	})
end

function M.autocomplete_fallback()
	augroup(group, { clear = false })

	autocmd("InsertCharPre", {
		group = group,
		desc = "Autocomplete using words in current file",
		callback = s.try_complete_fallback,
	})
end

function M.tab_complete(buffer)
	vim.keymap.set("i", "<Tab>", s.tab_expr, { buffer = buffer, expr = true })
	vim.keymap.set("i", "<S-Tab>", s.prev_item, { buffer = buffer, expr = true })
end

function M.tab_complete_fallback()
	vim.keymap.set("i", "<Tab>", s.complete_words, { expr = true })
	vim.keymap.set("i", "<S-Tab>", s.prev_item, { expr = true })
end

function M.toggle_menu(lhs, buffer)
	vim.keymap.set("i", lhs, s.toggle_expr, { buffer = buffer, expr = true })
end

function M.toggle_menu_fallback(lhs)
	vim.keymap.set("i", lhs, s.toggle_fallback, { expr = true })
end

function s.try_complete()
	if pumvisible() > 0 or s.is_macro() then
		return
	end

	if match(vim.v.char, pattern) >= 0 then
		vim.api.nvim_feedkeys(omni_code, "n", false)
	end
end

function s.try_complete_fallback()
	if pumvisible() > 0 or s.is_macro() or s.is_prompt() then
		return
	end

	if match(vim.v.char, pattern) >= 0 then
		vim.api.nvim_feedkeys(buffer_code, "n", false)
	end
end

function s.backspace(buffer)
	local rhs = function()
		if pumvisible() == 1 then
			return "<bs><c-x><c-o>"
		end

		return "<bs>"
	end

	vim.keymap.set("i", "<bs>", rhs, { expr = true, buffer = buffer })
end

function s.keymap(lhs, action)
	if lhs == nil or string.lower(lhs) == string.lower(action) then
		return
	end

	local rhs = function()
		if pumvisible() == 1 then
			return action
		end

		return lhs
	end

	vim.keymap.set("i", lhs, rhs, { expr = true })
end

function s.has_words_before()
	local cursor = vim.api.nvim_win_get_cursor(0)
	local col = cursor[2]

	if col == 0 then
		return false
	end

	local line = cursor[1]
	local str = vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]

	return str:sub(col, col):match("%s") == nil
end

function s.is_macro()
	return vim.fn.reg_recording() ~= "" or vim.fn.reg_executing() ~= ""
end

function s.is_prompt()
	return vim.api.nvim_buf_get_option(0, "buftype") == "prompt"
end

function s.tab_expr()
	if pumvisible() == 1 then
		return key.next_item
	end

	if s.has_words_before() then
		return key.omni
	end

	return key.tab
end

function s.complete_words()
	if pumvisible() == 1 then
		return key.next_item
	end

	if s.has_words_before() then
		return key.buffer
	end

	return key.tab
end

function s.prev_item()
	if pumvisible() == 1 then
		return key.prev_item
	end

	return key.tab
end

function s.toggle_expr()
	if pumvisible() == 1 then
		return key.abort
	end

	return key.omni
end

function s.toggle_fallback()
	if pumvisible() == 1 then
		return key.abort
	end

	return key.buffer
end

return M
