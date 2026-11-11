return function()
	local git = require("git")

	CACHE_HOME = os.getenv("XDG_CACHE_HOME") or (os.getenv("HOME") .. "/.cache")
	local cache_dir = CACHE_HOME .. "/vscode-neovim/plugins"

	local plugins = {
		{ path = "vim-denops/denops.vim", branch = "main" },
	}
	for _, plugin in ipairs(plugins) do
		local url = "https://github.com/" .. plugin.path
		local dest = cache_dir .. "/repos/github.com/" .. plugin.path
		git.clone(url, plugin.branch, dest)
		vim.opt.runtimepath:append(dest)
	end

end
