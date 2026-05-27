-- lua_add {{{
vim.opt.runtimepath:append(vim.fn.expand('$XDG_CACHE_HOME/treesitter/parsers'))
-- }}}
-- lua_source {{{
local ts = require('nvim-treesitter')

ts.setup {
	install_dir = vim.fn.expand('$XDG_CACHE_HOME/treesitter/parsers'),
}

vim.api.nvim_create_autocmd("FileType", {
	group = vim.api.nvim_create_augroup("UserTreesitter", { clear = true }),
	callback = function(args)
		local bufnr = args.buf
		local ft = vim.bo[bufnr].filetype
		local lang = vim.treesitter.language.get_lang(ft) or ft

		-- Auto install if missing (mimic old auto_install)
		local is_installed = #vim.api.nvim_get_runtime_file('parser/' .. lang .. '.so', false) > 0
		if not is_installed then
			-- pcall to avoid errors if the language doesn't have a parser available
			pcall(ts.install, { lang })
		end

		-- Check file size for performance
		local max_filesize = 100 * 1024 -- 100 KB
		local stats = vim.uv.fs_stat(vim.api.nvim_buf_get_name(bufnr))
		if stats and stats.size > max_filesize then
			return
		end

		-- Start treesitter
		if lang then
			pcall(vim.treesitter.start, bufnr, lang)
		end

		-- Enable indent
		vim.bo[bufnr].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
	end,
})
-- }}}
