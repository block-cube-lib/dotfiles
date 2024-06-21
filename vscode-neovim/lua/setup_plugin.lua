return function()
	local git = require("git")

	CACHE_HOME = os.getenv("XDG_CACHE_HOME") or (os.getenv("HOME") .. "/.cache")
	local cache_dir = CACHE_HOME .. "vscode-neovim/plugins"

	local plugins = {
		{ path = "vim-denops/denops.vim", branch = "main" },
		-- { path = "vim-skk/skkeleton.git", branch = "main" },
	}
	for _, plugin in ipairs(plugins) do
		local url = "https://github.com/" .. plugin.path
		local dest = cache_dir .. "/repos/github.com/" .. plugin.path
		git.clone(url, plugin.branch, dest)
		vim.opt.runtimepath:append(dest)
	end

	-- vim.api.nvim_create_autocmd({ 'User' }, {
	-- 	pattern = { 'skkeleton-initialize-pre' },
	-- 	callback = function()
	-- 		local cache_home = os.getenv('XDG_CACHE_HOME')
	-- 		local dict_dir = cache_home .. '/dpp/repos/github.com/skk-dev/dict'
	-- 		vim.fn["skkeleton#config"]({
	-- 			globalDictionaries = { 
	-- 				dict_dir .. '/SKK-JISYO.L',
	-- 				dict_dir .. '/SKK-JISYO.emoji',
	-- 			},
	-- 			eggLikeNewline = true,
	-- 			debug = true,
	-- 		})
	-- 	end,
	-- })
	-- vim.api.nvim_create_autocmd({ 'User' }, {
	-- 	pattern = { 'DenopsPluginPost:skkeleton' },
	-- 	callback = function()
	-- 		vim.fn["skkeleton#initialize"]()
	-- 	end,
	-- })
	-- vim.api.nvim_create_autocmd({ 'User' }, {
	-- 	pattern = { 'skkeleton-mode-changed' },
	-- 	callback = function()
	-- 		print("mode = " .. vim.g['skkeleton#mode'])
	-- 	end,
	-- })
	-- vim.api.nvim_create_autocmd({ 'User' }, {
	-- 	pattern = { 'skkeleton-handled' },
	-- 	callback = function()
	-- 		for i, v in ipairs(vim.g['skkeleton#state']) do
	-- 			print("state[" .. i .. "] = " .. v)
	-- 		end
	-- 	end,
	-- })
	-- vim.keymap.set({ 'i', 'c', 't' }, '<C-j>', [[<Plug>(skkeleton-toggle)]], { noremap = false, silent = true })
	-- vim.keymap.set({ 'i', 'c', 't' }, '<C-k>', [[<Cmd>echo "hoge"<CR>]], { noremap = false, silent = true })
	-- vim.keymap.set({ 'i', 'c', 't' }, '<C-l>', [[<Plug>(skkeleton-disable)]], { noremap = false, silent = true })
end
