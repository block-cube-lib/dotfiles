local nvim_base_dir = (os.getenv("XDG_CONFIG_HOME") or os.getenv("HOME")) .. "/nvim"
vim.opt.runtimepath:append(nvim_base_dir)

require("base")

vim.keymap.set('i', '<C-j>', '')

if vim.g.vscode then
	vim.keymap.set('n', 'gd', [[<Cmd>call VSCodeCall('editor.action.revealDefinition')<CR>]],
		{ noremap = true, silent = true })
	vim.keymap.set({ 'n', 'v' }, '<Leader>r', [[<Cmd>call VSCodeCall('editor.action.rename')<CR>]],
		{ noremap = true, silent = true })
end

require("setup_plugin")()
