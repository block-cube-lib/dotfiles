local git = {}

git.clone = function(repo, branch, dest)
	if not vim.loop.fs_stat(dest) then
		vim.notify("clone " .. repo)
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

return git
