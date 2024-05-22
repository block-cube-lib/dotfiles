-- lua_add {{{
vim.keymap.set('n', '<Leader>gs', [[<Cmd>GinStatus<CR>]], { noremap = true, silent = true })
vim.keymap.set('n', '<Leader>gS', [[<Cmd>GinStatus ++opener=split<CR>]], { noremap = true, silent = true })
vim.keymap.set('n', '<Leader>gb', [[<Cmd>GinBranch ++opener=split<CR>]], { noremap = true, silent = true })
vim.api.nvim_create_autocmd('FileType', {
	pattern = { 'gin-status' },
	callback = function(ev)
		local opt = { noremap = true, silent = true, buffer = ev.buf }
		vim.keymap.set('n', '<C-r>', [[<Cmd>GinStatus<CR>]], opt)
	end,
})
-- }}}
