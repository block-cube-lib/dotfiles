local function gitClone(repo, branch, dest)
	if not vim.loop.fs_stat(dest) then
		vim.fn.system({
			"git",
			"clone",
			"--filter=blob:none",
			repo,
			"--branch=" .. branch,
			dest,
		})
	end
end

return function()
	CONFIG_HOME = os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config")
	CACHE_HOME = os.getenv("XDG_CACHE_HOME") or (os.getenv("HOME") .. "/.cache")
	local dppBase = CACHE_HOME .. "/dpp/"
	local dppSrc = dppBase .. "repos/github.com/Shougo/dpp.vim"
	local denopsSrc = dppBase .. "repos/github.com/vim-denops/denops.vim"
	local denopsInstaller = CACHE_HOME .. "repos/github.com/Shougo/dpp-ext-installer"

	gitClone("https://github.com/Shougo/dpp.vim", "main", dppSrc)
	gitClone("https://github.com/vim-denops/denops.vim", "main", denopsSrc)
	vim.opt.runtimepath:prepend(dppSrc)

	local dppExtends = {
		"Shougo/dpp-ext-installer",
		"Shougo/dpp-protocol-git",
		"Shougo/dpp-ext-lazy",
		"Shougo/dpp-ext-toml",
	}
	for _, plugin in ipairs(dppExtends) do
		local dest = dppBase .. "repos/github.com/" .. plugin
		gitClone("https://github.com/" .. plugin, "main", dest)
		vim.opt.runtimepath:append(dest)
	end

	local dpp = require("dpp")
	if dpp.load_state(dppBase) then
		vim.opt.runtimepath:prepend(denopsSrc)
		vim.opt.runtimepath:prepend(denopsInstaller)

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
end
