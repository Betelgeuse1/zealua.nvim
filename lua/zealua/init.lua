local M = {}

M.options = {
	location = "$HOME/.local/share/Zeal/Zeal/docsets",
	docsets = {},
	buffer_filetype = {},
}

M.setup = function(user_config)
	-- TODO extracts docsets from path and insert in M.docsets

	if user_config then
		vim.tbl_deep_extend("force", M.options, user_config)
	end

	-- user commands
	vim.api.nvim_create_user_command('Zeal', M.search, { nargs = '?', bang = true })
	-- vim.api.nvim_create_user_command('ZealEngine', M.engine, {})
	vim.api.nvim_create_user_command('ZealFT', M.filetype, { nargs = 1, bar = true, complete = M._completion })

	-- keymaps
	if user_config.keymaps then
		vim.api.nvim_set_keymap('n', 'gz', ':Zeal<CR>', { noremap = true })
	end
end

--====================================================
--==========              Zeal              ==========
--====================================================
M.engine = function()
	-- TODO Asks for both docset and search word (if non -> use <cword>)
	-- 		Uses the M.completion for the first argument only (might need some research)
end

M.search = function(cmd)
	local bufnr = vim.fn.bufnr()
	local filetype = M._get_filetype()
	local word = cmd.args ~= '' and cmd.fargs[1] or vim.fn.expand('<cword>')

	local search
	if cmd.bang then
		search = word
	else
		search = string.format('%s:%s', filetype, word)
	end

	M._launch(search)
end

-- Use to correct incoherent buffer filetype
M.filetype = function(cmd)
	local bufnr = vim.fn.bufnr()
	M.options.buffer_filetype[bufnr] = cmd.fargs[1]
end

--====================================================
--==========             Utils             ===========
--====================================================
M._launch = function(search)
	vim.cmd('!zeal ' .. search .. '&')
	M._clear_hit_enter()
end

M._get_filetype = function()
	local bufnr = vim.fn.bufnr()

	return M.options.buffer_filetype[bufnr] or vim.bo.filetype
end

M._completion = function(_, _, _)
	-- lazy loading docsets completion
	if not M.options.docsets then
		print("HELLO")
	end

	return M.options.docsets
end

M._clear_hit_enter = function()
	vim.fn.feedkeys('<CR>')
end

return M
