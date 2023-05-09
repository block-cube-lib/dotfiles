CONFIG_HOME = os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config")
CACHE_HOME = os.getenv("XDG_CACHE_HOME") or (os.getenv("HOME") .. "/.cache")

vim.cmd("autocmd!")

vim.scriptencoding = "utf-8"

vim.wo.number = true
vim.wo.cursorline = true
vim.opt.ruler = true

-- Restore cursor location when file is opened
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
vim.opt.backupdir = CACHE_HOME..'/nvim/backup'
vim.opt.swapfile = true
vim.opt.directory = CACHE_HOME..'/nvim/swap'
vim.opt.backup = true
vim.opt.backupdir = CACHE_HOME..'/nvim/backup'
vim.opt.undofile = true
vim.opt.undodir = CACHE_HOME..'/nvim/undo'

-- Editor
vim.opt.title = true
vim.opt.matchpairs = "(:),{:},[:],<:>,「:」,【:】,『:』"
vim.opt.list = true
vim.opt.listchars = "tab:>-,trail:~,eol:↴"
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
vim.opt.termguicolors = true

vim.opt.syntax = 'on'

vim.opt.cmdheight = 2
vim.opt.laststatus = 2
vim.opt.showcmd = true
vim.opt.wildmenu = true

if not vim.fn.exists('g:vscode') then
	vim.opt.ambiwidth = 'single'
end
