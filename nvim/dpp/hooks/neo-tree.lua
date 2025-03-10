-- lua_add {{{
vim.keymap.set('n', '<Leader>F', function()
	if vim.bo.filetype == 'neo-tree' then
		vim.cmd('Neotree close')
	else
		vim.cmd('Neotree')
	end
end, { noremap = true, silent = true })
-- }}}
