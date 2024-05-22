-- lua_add {{{
local deol_command = function(option)
	if option == nil then
		option = {}
	end
	if option['edit'] == nil then
		option['edit'] = true
	end
	option['edit_filetype'] = 'deol-edit'
	return function() vim.fn['deol#start'](option) end
end
local opt = { noremap = true, silent = true };
-- vim.keymap.set('n', '<Leader>tt', [[<Cmd>tabnew<CR>]] .. deol_command(), opt)
vim.keymap.set('n', '<Leader>tc', deol_command(), opt) -- current
vim.keymap.set('n', '<Leader>tf',
	deol_command({ split = 'floating', edit = false, winheight = 30, winwidth = 160 }), opt)
vim.keymap.set('n', '<Leader>tv', deol_command({ split = 'vertical' }), opt)
vim.keymap.set('n', '<Leader>tr', deol_command({ split = 'farright' }), opt)
vim.keymap.set('n', '<Leader>tl', deol_command({ split = 'farleft' }), opt)

vim.g["deol#prompt_pattern"] = "❯ ";
vim.g["deol#extra_options"] = { term_finish = 'close' }

vim.api.nvim_create_autocmd('FileType', {
	pattern = { 'deol-edit' },
	callback = function(ev)
		vim.keymap.set('i', '<C-Q>', [[<Esc>]], { noremap = true, silent = true })
	end,
})
-- }}}
