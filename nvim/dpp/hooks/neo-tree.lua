-- lua_add {{{
vim.keymap.set('n', '<Leader>Fo', function()
	vim.cmd('Neotree')
end, { noremap = true, silent = true })
vim.keymap.set('n', '<Leader>Fc', function()
	vim.cmd('Neotree close')
end, { noremap = true, silent = true })
-- }}}
