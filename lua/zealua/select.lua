local M = {}

-- Thanks for the inspiration <3
-- https://www.reddit.com/r/neovim/comments/ua6826/3_lua_override_vimuiinput_in_40_lines
M.open_docset_selector = function(completion, callback)
	local prompt_text = 'Docset: '
	local buf = M._create_prompt(prompt_text, callback)

	-- Set the autocmd after the startinsert call so
	-- we don't call this function once for nothing.
	vim.api.nvim_create_autocmd('TextChangedI', {
		buffer = buf,
		callback = function()
			local text = vim.api.nvim_get_current_line()
			local input = string.sub(text, #prompt_text + 1)
			local items = M._generate_items(completion(input))
			vim.api.nvim_buf_set_lines(buf, 0, 9, false, items)
		end
	})

	-- Open the prompt window
	M._open_window(buf, 20, 10)
end

M.search_input = function(callback)
	local buf = M._create_prompt('Search: ', callback)
	M._open_window(buf, 20, 1)
end

M._create_prompt = function(prompt_text, callback)
	local buf = vim.api.nvim_create_buf(false, false)
	-- buffer options
	vim.bo[buf].buftype = 'prompt'
	vim.bo[buf].bufhidden = 'wipe'

	-- slightly defer the callback so potential
	-- new window don't smash together
	local deferred = function(input)
		vim.defer_fn(function()
			callback(input)
		end, 10)
	end

	-- prompt settings
	vim.fn.prompt_setprompt(buf, prompt_text)
	vim.fn.prompt_setcallback(buf, deferred)

	return buf
end

M._open_window = function(buf, width, height)
	local hw = width / 2
	local hh = height / 2

	-- Set keymaps
	M._set_keymaps(buf)

	vim.api.nvim_open_win(buf, true, {
		relative = 'editor',
		row = vim.o.lines / 2 - hh,
		col = vim.o.columns / 2 - hw,
		width = width,
		height = height,
		style = 'minimal',
		border = 'single',
		noautocmd = true,
	})

	vim.cmd('startinsert')
end

M._set_keymaps = function(buf)
	-- Keymaps yanked straight from the redis post
	vim.keymap.set({ "i", "n" }, "<CR>", "<Esc><CR><Esc>:close!<CR>:stopinsert<CR>", {
		silent = true,
		buffer = buf,
	})

	vim.keymap.set("n", "<esc>", function()
		return vim.fn.mode() == "n" and "ZQ" or "<esc>"
	end, {
		expr = true, silent = true, buffer = buf
	})

	vim.keymap.set("n", "q", function()
		return vim.fn.mode() == "n" and "ZQ" or "<esc>"
	end, {
		expr = true, silent = true, buffer = buf
	})
end

M._generate_items = function(values)
	local items = {}

	for i = 1, 9 do
		items[i] = values[i] or ""
	end

	return items
end

return M
