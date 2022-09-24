local M = {}

M.options = {
	location = "$HOME/.local/share/Zeal/Zeal/docsets",
	completion_cmd = "find %s -maxdepth 4 -name Info.plist -exec grep -o -m 1 -E '<string>[a-z]*</string>' {} \\; | uniq",
	install_docsets = {},
	buffer_docset = {},
}

M.setup = function(user_config)
	-- TODO extracts docsets from path and insert in M.docsets

	if user_config then
		vim.tbl_deep_extend("force", M.options, user_config)
	end

	-- user commands
	vim.api.nvim_create_user_command('Zeal', M.zsearch, { nargs = '?', bang = true })
	vim.api.nvim_create_user_command('ZealSelect', M.zselect, {})
	vim.api.nvim_create_user_command('ZealFT', M.zfiletype, { nargs = 1, bar = true, complete = M._completion })

	-- keymaps
	if M.options.auto_keymaps then
		-- Open zeal using <cword> and M.filetype
		vim.api.nvim_set_keymap('n', 'gz', ':Zeal<CR>', { noremap = true })
		-- Open zeal select window
		vim.api.nvim_set_keymap('n', 'gZ', ':ZealSelect<CR>', { noremap = true })
	end
end

--====================================================
--==========              Zeal              ==========
--====================================================

M.zsearch = function(cmd)
	local docset = M._get_docset()
	local word = cmd.args ~= '' and cmd.fargs[1] or vim.fn.expand('<cword>')

	local search = word
	if not cmd.bang then
		search = string.format('%s:%s', docset, word)
	end

	M._launch(search)
end

-- TODO Asks for both docset and search word (if non -> use <cword>)
-- 		Uses the M.completion for the first argument only (might need some research)
M.zselect = function()
	local sel = require('zealua.lua.zealua.select')

	sel.open_docset_selector(M._completion, function(docset)
		print(docset)
		sel.search_input(function(word)
			M._launch(docset .. ':' .. word)
		end)
	end)

end

-- Use to correct incoherent buffer filetype
M.zfiletype = function(cmd)
	local bufnr = vim.fn.bufnr()
	M.options.buffer_docset[bufnr] = cmd.fargs[1]
end

--====================================================
--==========             Utils             ===========
--====================================================
M._launch = function(search)
	vim.cmd('!zeal ' .. search .. '&')
	M._clear_hit_enter()
end

M._get_docset = function()
	local bufnr = vim.fn.bufnr()

	return M.options.buffer_docset[bufnr] or vim.bo.filetype
end

M._completion = function(current, _, _)
	-- lazy loading docsets for completion when they're first needed
	-- MAYBE: switch to file based solution (load/save from/to a docsets.lua)
	if #M.options.install_docsets == 0 then
		M._fill_completion()
	end

	if not current or current == '' then
		return M.options.install_docsets
	end

	local possible_values = {}
	for _, docset in ipairs(M.options.install_docsets) do
		if string.find(docset, '^' .. current) then
			table.insert(possible_values, docset)
		end
	end

	return possible_values
end

M._fill_completion = function()
	local command = string.format(M.options.completion_cmd, M.options.location)
	local results = io.popen(command, "r")
	if not results then
		return
	end

	M.options.install_docsets = {}
	for line in results:lines() do
		-- since all lines follow the same pattern
		-- <script>the_dash_name</script>
		-- we can just grab the middle value with a simple
		-- string.sub call.
		local docset = string.sub(line, 9, -10)
		table.insert(M.options.install_docsets, docset)
	end
	results:close()
end

M._clear_hit_enter = function()
	vim.fn.feedkeys('<CR>')
end

return M
