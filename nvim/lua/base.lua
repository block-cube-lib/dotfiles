vim.cmd("autocmd!")

vim.scriptencoding = "utf-8"

vim.wo.number = true
vim.wo.cursorline = true
vim.opt.ruler = true

-- Restore cursor location when file is opened
local autogroup = vim.api.nvim_create_augroup -- Create/get autocommand group
local autocmd = vim.api.nvim_create_autocmd -- Create autocommand
autocmd({ "BufReadPost" }, {
	pattern = { "*" },
	callback = function()
		vim.api.nvim_exec('silent! normal! g`"zv', false)
	end,
})

-- Encoding
vim.opt.encoding = "utf-8"
vim.opt.fileencoding = "utf-8"

-- System files
vim.opt.backup = true
vim.opt.backupdir = cache_home..'/nvim/backup'
vim.opt.swapfile = true
vim.opt.directory = cache_home..'/nvim/swap'
vim.opt.backup = true
vim.opt.backupdir = cache_home..'/nvim/backup'
vim.opt.termguicolors = true

-- Editor
vim.opt.title = true
vim.opt.matchpairs = "(:),{:},[:],<:>,「:」,【:】,『:』"
vim.opt.list = true
vim.opt.listchars = "tab:>-,trail:~"
vim.opt.hidden = true
vim.opt.wrap = false
vim.opt.showmatch = true
vim.opt.matchtime = 1

-- indent
vim.opt.expandtab = true
vim.opt.cindent = true

-- serach
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.wrapscan = true

-- other
vim.opt.syntax = 'on'

vim.opt.cmdheight = 2
vim.opt.laststatus = 2
vim.opt.showcmd = true
vim.opt.wildmenu = true

if not vim.fn.exists('g:vscode') then
	vim.opt.ambiwidth = single
end
