-- lua_add {{{
vim.api.nvim_create_autocmd({ 'User' }, {
	pattern = { 'skkeleton-initialize-pre' },
	callback = function()
		local cache_home = os.getenv('XDG_CACHE_HOME')
		local dict_dir = cache_home .. '/dpp/repos/github.com/skk-dev/dict'
		vim.fn["skkeleton#config"]({
			globalDictionaries = { 
				dict_dir .. '/SKK-JISYO.L',
				dict_dir .. '/SKK-JISYO.emoji',
			},
			eggLikeNewline = true,
		})
	end,
})
vim.api.nvim_create_autocmd({ 'User' }, {
	pattern = { 'DenopsPluginPost:skkeleton' },
	callback = function()
		vim.fn["skkeleton#initialize"]()
	end,
})
vim.keymap.set({ 'i', 'c', 't' }, '<C-j>', [[<Plug>(skkeleton-toggle)]], { noremap = false })
-- }}}
