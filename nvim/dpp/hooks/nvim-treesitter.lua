-- lua_add {{{
vim.opt.runtimepath:append('$XDG_CACHE_HOME/treesitter/parsers')
-- }}}
-- lua_source {{{
vim.treesitter.start = (function(wrapped)
	return function(bufnr, lang)
		lang = lang or vim.fn.getbufvar(bufnr or '', '&filetype')
		pcall(wrapped, bufnr, lang)
	end
end)(vim.treesitter.start)

require('nvim-treesitter.configs').setup {
	parser_install_dir = '$XDG_CACHE_HOME/treesitter/parsers',
	sync_install = false,
	auto_install = true,
	highlight = {
		enable = true,
		-- Or use a function for more flexibility, e.g. to disable slow treesitter highlight for large files
		disable = function(lang, buf)
			local max_filesize = 100 * 1024 -- 100 KB
			local ok, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(buf))
			if ok and stats and stats.size > max_filesize then
				return true
			end
		end,
		additional_vim_regex_highlighting = false,
	},
	indent = {
		enable = true,
	},
}
-- }}}
