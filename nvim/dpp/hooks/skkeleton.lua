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
vim.keymap.set({ 'i', 'c' }, '<C-j>', [[<Plug>(skkeleton-toggle)]], { noremap = false })
-- Terminal mode: skkeleton supports it (it ships a tnoremap
-- for <Plug>(skkeleton-toggle) and replays its rewrites as
-- terminal input), so <C-j> toggles there too -- but only
-- once skkeleton has loaded. It is lazy-loaded on
-- InsertEnter/CmdlineEnter, and feeding the <Plug> before
-- that would leak the literal text "(skkeleton-toggle)"
-- into the job, so until the target exists the raw key
-- goes to the job as-is (a newline in gemini's input, a
-- line feed in shells).
vim.keymap.set('t', '<C-j>', function()
	if vim.fn.maparg('<Plug>(skkeleton-toggle)', 't') == '' then
		local job = vim.b.terminal_job_id
		if job then
			vim.fn.chansend(job, '\n')
		end
	else
		vim.api.nvim_feedkeys(
			vim.api.nvim_replace_termcodes(
				'<Plug>(skkeleton-toggle)', true, false, true),
			'm', false)
	end
end)
-- }}}
