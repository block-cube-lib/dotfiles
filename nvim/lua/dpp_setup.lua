return function()
	local git = require("git")

	CONFIG_HOME = os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config")
	CACHE_HOME = os.getenv("XDG_CACHE_HOME") or (os.getenv("HOME") .. "/.cache")
	local dppBase = CACHE_HOME .. "/dpp"
	local dppSrc = dppBase .. "/repos/github.com/Shougo/dpp.vim"
	local denopsSrc = dppBase .. "/repos/github.com/vim-denops/denops.vim"
	local dppExtInstaller = CACHE_HOME .. "/repos/github.com/Shougo/dpp-ext-installer"

	git.clone("https://github.com/Shougo/dpp.vim", "main", dppSrc)
	git.clone("https://github.com/vim-denops/denops.vim", "main", denopsSrc)
	vim.opt.runtimepath:prepend(dppSrc)

	local dppExtends = {
		"Shougo/dpp-ext-installer",
		"Shougo/dpp-protocol-git",
		"Shougo/dpp-ext-lazy",
		"Shougo/dpp-ext-toml",
	}
	for _, plugin in ipairs(dppExtends) do
		local dest = dppBase .. "/repos/github.com/" .. plugin
		git.clone("https://github.com/" .. plugin, "main", dest)
		vim.opt.runtimepath:append(dest)
	end

	local dpp = require("dpp")
	if dpp.load_state(dppBase) then
		vim.opt.runtimepath:prepend(denopsSrc)
		vim.opt.runtimepath:prepend(dppExtInstaller)

		vim.fn["denops#server#wait_async"](function()
			vim.notify("dpp load_state() is failed")
			dpp.make_state(dppBase, CONFIG_HOME .. "/nvim/dpp.ts")
		end)
	end

	vim.api.nvim_create_autocmd("User", {
		pattern = "Dpp:makeStatePort",
		callback = function()
			vim.notify("dpp make_state() is done")
		end,
	})

	vim.cmd("filetype indent plugin on")
	vim.cmd("syntax on")

	vim.api.nvim_create_user_command('DppInstall', "call dpp#async_ext_action('installer', 'install')", {})
	vim.api.nvim_create_user_command(
		'DppUpdate', 
		function(opts)
			local args = opts.fargs
			vim.fn['dpp#async_ext_action']('installer', 'update', { names = args })
		end, 
		{ nargs = '*' }
	)
end
