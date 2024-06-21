-- lua_add {{{
local deol_command = function(option)
	if option == nil then
		option = {}
	end
	if option['edit'] == nil then
		option['edit'] = true
	end
	option['edit_filetype'] = 'deol-edit'
	option['prompt_pattern'] = '> '
	return function()
		vim.fn['deol#start'](option)
		vim.fn['deol#set_option']('extra_term_options', {
			term_finish= 'close',
		})
	end
end
local opt = { noremap = true, silent = true };
-- vim.keymap.set('n', '<Leader>tt', [[<Cmd>tabnew<CR>]] .. deol_command(), opt)
vim.keymap.set('n', '<Leader>tc', deol_command(), opt) -- current
vim.keymap.set('n', '<Leader>tf',
	deol_command({ split = 'floating', edit = false, winheight = 30, winwidth = 160 }), opt)
vim.keymap.set('n', '<Leader>tv', deol_command({ split = 'vertical' }), opt)
vim.keymap.set('n', '<Leader>tr', deol_command({ split = 'farright' }), opt)
vim.keymap.set('n', '<Leader>tl', deol_command({ split = 'farleft' }), opt)

vim.g["deol#extra_options"] = { term_finish = 'close' }

vim.api.nvim_create_autocmd('FileType', {
	pattern = { 'deol' },
	callback = function()
		local opt = { noremap = true, buffer = true, silent = true };
		vim.keymap.set('i', '<C-n>', [[<Plug>(deol_next_prompt]], opt)
		vim.keymap.set('i', '<C-p>', [[<Plug>(deol_previous_prompt)]], opt)
		vim.keymap.set('n', '<CR>', [[<Plug>(deol_execute_line)]], opt)
		vim.keymap.set('n', 'A', [[<Plug>(deol_start_append_last)]], opt)
		vim.keymap.set('n', 'I', [[<Plug>(deol_start_insert_first)]], opt)
		vim.keymap.set('n', 'a', [[<Plug>(deol_start_append)]], opt)
		vim.keymap.set('n', 'e', [[<Plug>(deol_edit)]], opt)
		vim.keymap.set('n', 'i', [[<Plug>(deol_start_insert)]], opt)
		vim.keymap.set('n', 'q', [[<Plug>(deol_quit)]], opt)
	end
})
vim.api.nvim_create_autocmd('FileType', {
	pattern = { 'deol-edit' },
	callback = function(ev)
		local opt = { noremap = true, buffer = true, silent = true }
		vim.keymap.set('i', '<C-Q>', [[<Esc>]], opt)
		vim.keymap.set({'n', 'i'}, '<CR>', [[<Plug>(deol_execute_line)]], opt)
	end,
})
-- }}}
