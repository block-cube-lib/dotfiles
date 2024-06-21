-- lua_add {{{
vim.keymap.set('n', '<Leader>df',
	function()
		local searchPath = string.format("\"%s\"", vim.fn["expand"]('%:p'))
		vim.fn["ddu#start"]({
			name = 'filer',
			searchPath = searchPath,
		})
		print("searchPath: " .. searchPath)
	end,
	{ noremap = true, silent = true })
vim.keymap.set('n', '<Leader>dF', [[<Cmd>call ddu#start(#{ name: 'file_recursive' })<CR>]],
	{ noremap = true, silent = true })
vim.keymap.set('n', '<Leader>db', [[<Cmd>call ddu#start(#{ sources: [#{ name: 'buffer' }] })<CR>]],
	{ noremap = true, silent = true })
-- }}}

-- lua_source {{{
function is_unity_dir() 
	local assembly_csproj = vim.fn.globpath(vim.fn.getcwd(), 'Assembly-CSharp.csproj')
	return assembly_csproj ~= ''
end

local ignore_directories = { 'target', '.git', '.vscode' }

if is_unity_dir() then
	table.insert(ignore_directories, 'Library')
	table.insert(ignore_directories, 'Logs')
	table.insert(ignore_directories, 'Temp')
end

vim.fn["ddu#custom#patch_global"]({
	ui = 'ff',
	sources = {
		{ name = 'file' },
	},
	uiParams = {
		ff = {
			split = 'floating',
			prompt = '> ',
		},
	},
	kindOptions = {
		file = { defaultAction = 'open' },
	},
	sourceOptions = {
		_ = {
			matchers = { 'matcher_substring' },
			sorters = { 'sorter_alpha' },
		},
	},
})
vim.fn["ddu#custom#patch_local"]('filer', {
	ui = 'filer',
	sources = {
		{ name = 'file' },
	},
	uiParams = {
		filer = {
			winWidth = 40,
			split = 'vertical',
			splitDirection = 'topleft',
		}
	},
	kindOptions = {
		file = { defaultAction = 'open', }
	},
	sourceOptions = {
		_ = {
			columns = { 'filename' },
		},
	},
	actionOptions = {
		narrow = { quit = false }
	},
})
vim.fn["ddu#custom#patch_local"]('file_recursive', {
	ui = {
		name = "ff",
	},
	sources = {
		{
			name = { 'file_rec' },
			options = {
			},
			params = {
				ignoredDirectories = ignore_directories,
			},
			kindOptions = {
				file = { defaultAction = 'open', }
			},
		},
	}
})

vim.api.nvim_create_autocmd('FileType', {
	pattern = { 'ddu-ff' },
	callback = function(ev)
		-- (ddu#ui#get_item()['__sourceName'] == 'buffer') ?
		local opt = { noremap = true, silent = true, buffer = ev.buf }
		vim.keymap.set('n', '<CR>', [[<Cmd>call ddu#ui#do_action('itemAction')<CR>]],
			{ noremap = true, silent = true })
		vim.keymap.set('n', 'S',
			[[<Cmd>call ddu#ui#do_action('itemAction', {'name': 'open', 'params': {'command': 'split'}})<CR>]],
		opt)
		vim.keymap.set('n', 'V',
			[[<Cmd>call ddu#ui#do_action('itemAction', {'name': 'open', 'params': {'command': 'vsplit'}})<CR>]],
		opt)
		vim.keymap.set('n', 'T',
			[[<Cmd>call ddu#ui#do_action('itemAction', {'name': 'open', 'params': {'command': 'tabedit'}})<CR>]],
		opt)
		vim.keymap.set('n', '<Esc>', [[<Cmd>call ddu#ui#do_action('quit')<CR>]], opt)
		vim.keymap.set('n', 'p', [[<Cmd>call ddu#ui#do_action('preview')<CR>]], opt)
		vim.keymap.set('n', 'd', [[<Cmd>call ddu#ui#do_action('itemAction', {'name': 'delete'})<CR>]], opt)
		vim.keymap.set('n', '<C-l>', [[<Cmd>call ddu#ui#do_action('itemAction', {'name': 'refresh'})<CR>]],
		opt)
		vim.keymap.set('n', 'i', [[<Cmd>call ddu#ui#do_action('openFilterWindow')<CR>]], opt)
	end,
})
vim.api.nvim_create_autocmd('FileType', {
	pattern = { 'ddu-ff-filter' },
	callback = function(ev)
		local opt = { noremap = true, silent = true, buffer = ev.buf }
		vim.keymap.set('i', '<CR>', [[<Esc><Cmd>call ddu#ui#do_action('closeFilterWindow')<CR>]], opt)
		vim.keymap.set('i', '<Esc>', [[<Esc><Cmd>call ddu#ui#do_action('closeFilterWindow')<CR>]], opt)
		vim.keymap.set('n', '<CR>', [[<Esc><Cmd>call ddu#ui#do_action('closeFilterWindow')<CR>]], opt)
		vim.keymap.set('n', '<Esc>', [[<Esc><Cmd>call ddu#ui#do_action('closeFilterWindow')<CR>]], opt)
		vim.keymap.set('n', 'o', [[<Cmd>call ddu#ui#do_action('itemAction', {'name': 'open'})<CR>]], opt)
	end,
})

vim.api.nvim_create_autocmd({ 'TabEnter', 'CursorHold', 'FocusGained' }, {
	command = "call ddu#ui#do_action('checkItems')"
})
vim.api.nvim_create_autocmd('FileType', {
	pattern = { 'ddu-filer' },
	callback = function(ev)
		local opt = { noremap = true, silent = true, buffer = ev.buf }
		local crAction = function()
			if vim.fn['ddu#ui#get_item']()['action']['isDirectory'] then
				vim.fn["ddu#ui#do_action"]('expandItem', { mode = 'toggle' })
			else
				vim.fn["ddu#ui#do_action"]('itemAction', { name = 'open' })
			end
		end
		vim.keymap.set('n', '<CR>', crAction, opt)
		vim.keymap.set('n', 'o', [[<Cmd>call ddu#ui#do_action('expandItem', {'mode': 'toggle'})<CR>]],
		opt)
		vim.keymap.set('n', '<Space>',
			[[<Cmd>call ddu#ui#do_action('expandItem', {'mode': 'toggle'})<CR>]], opt)
		vim.keymap.set('n', '<Esc>', [[<Cmd>call ddu#ui#do_action('quit')<CR>]], opt)
		vim.keymap.set('n', 'c', [[<Cmd>call ddu#ui#do_action('itemAction', {'name': 'copy'})<CR>]],
		opt)
		vim.keymap.set('n', 'p', [[<Cmd>call ddu#ui#do_action('itemAction', {'name': 'paste'})<CR>]],
		opt)
		vim.keymap.set('n', 'd', [[<Cmd>call ddu#ui#do_action('itemAction', {'name': 'delete'})<CR>]],
		opt)
		vim.keymap.set('n', 'r', [[<Cmd>call ddu#ui#do_action('itemAction', {'name': 'rename'})<CR>]],
		opt)
		vim.keymap.set('n', 'mv', [[<Cmd>call ddu#ui#do_action('itemAction', {'name': 'move'})<CR>]],
		opt)
		vim.keymap.set('n', 't', [[<Cmd>call ddu#ui#do_action('itemAction', {'name': 'newFile'})<CR>]],
		opt)
		vim.keymap.set('n', 'mk',
			[[<Cmd>call ddu#ui#do_action('itemAction', {'name': 'newDirectory'})<CR>]], opt)
		vim.keymap.set('n', 'yy', [[<Cmd>call ddu#ui#do_action('itemAction', {'name': 'yank'})<CR>]],
		opt)
		vim.keymap.set('n', 'S',
			[[<Cmd>call ddu#ui#do_action('itemAction', {'name': 'open', 'params': {'command': 'split'}})<CR>]],
		opt)
		vim.keymap.set('n', 'V',
			[[<Cmd>call ddu#ui#do_action('itemAction', {'name': 'open', 'params': {'command': 'vsplit'}})<CR>]],
		opt)
		vim.keymap.set('n', 'T',
			[[<Cmd>call ddu#ui#do_action('itemAction', {'name': 'open', 'params': {'command': 'tabedit'}})<CR>]],
		opt)
	end,
})
-- }}}
