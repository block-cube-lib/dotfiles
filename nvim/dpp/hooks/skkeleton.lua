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
-- No 't' here: skkeleton is lazy-loaded on InsertEnter, so in
-- a terminal buffer pressed before that, the <Plug> target
-- does not exist yet and the literal text "(skkeleton-toggle)"
-- is sent to the job. SKK input for terminals goes through
-- insert-mode buffers anyway (deol-edit, the agent board's
-- compose buffer); in a raw terminal <C-j> must reach the
-- job as-is.
vim.keymap.set({ 'i', 'c' }, '<C-j>', [[<Plug>(skkeleton-toggle)]], { noremap = false })
-- }}}
