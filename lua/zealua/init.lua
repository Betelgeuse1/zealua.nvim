local M = {}

M.options = {
	location = "$HOME/.local/share/Zeal/Zeal/docsets",
	completion_cmd = "find %s -maxdepth 4 -name Info.plist -exec grep -o -m 1 -E '<string>[a-z]*</string>' {} \\; | uniq",
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
	vim.api.nvim_create_user_command('ZealEngine', M.engine, {})
	vim.api.nvim_create_user_command('ZealFT', M.filetype, { nargs = 1, bar = true, complete = M._completion })

	-- keymaps
	if user_config.keymaps then
		vim.api.nvim_set_keymap('n', 'gz', ':Zeal<CR>', { noremap = true })
	end
end

--====================================================
--==========              Zeal              ==========
--====================================================

M.search = function(cmd)
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

M.engine = function(cmd)
	-- TODO Asks for both docset and search word (if non -> use <cword>)
	-- 		Uses the M.completion for the first argument only (might need some research)
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
	-- lazy loading docsets completion when they're first needed
	if #M.options.docsets == 0 then
		M._fill_completion()
	end

	return M.options.docsets
end

M._fill_completion = function()
	local command = string.format(M.options.completion_cmd, M.options.location)
	local results = io.popen(command, "r")
	if not results then
		return
	end

	for line in results:lines() do
		-- since all lines follow the same pattern
		-- <script>the_dash_name</script>
		-- we can just grab the middle value with a simple
		-- string.sub call.
		local docset = string.sub(line, 9, -10)
		table.insert(M.options.docsets, docset)
	end
	results:close()
end

M._clear_hit_enter = function()
	vim.fn.feedkeys('<CR>')
end

return M
