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

-- terminal
if vim.fn.has('windows') and vim.fn.executable('nu') then
	vim.opt.sh = 'nu'
end

-- other
vim.opt.termguicolors = true

vim.opt.syntax = 'on'

vim.opt.cmdheight = 2
vim.opt.laststatus = 2
vim.opt.showcmd = true
vim.opt.wildmenu = true

if not vim.g.vscode then
	vim.opt.ambiwidth = 'single'
end

---------------------------------------------------
-- key map
---------------------------------------------------
vim.g.mapleader = ' '

-- terminal
vim.keymap.set('t', '<C-Q>', [[<C-\><C-n>]], { noremap = true, silent = true })

-- vscode
if vim.g.vscode then
	vim.keymap.set('n', 'gd', [[<Cmd>call VSCodeCall('editor.action.revealDefinition')<CR>]], { noremap = true, silent = true })
	vim.keymap.set({'n', 'v'}, '<Leader>r', [[<Cmd>call VSCodeCall('editor.action.rename')<CR>]], { noremap = true, silent = true })
end

---------------------------------------------------
-- plugins
---------------------------------------------------
local plugins = {
	{
		"folke/tokyonight.nvim",
		lazy = false,
		priority = 1000,
		config = function()
			vim.cmd([[colorscheme tokyonight]])
		end,
	},
	{
		"lukas-reineke/indent-blankline.nvim",
		lazy = false,
		cond = not vim.g.vscode,
		opts = {
			show_end_of_line = true,
		}
	},
	{
		"nvim-treesitter/nvim-treesitter",
		lazy = false,
		config = function()
			require('nvim-treesitter.configs').setup {
				sync_install = false,
				auto_install = true,
				highlight = {
					enable = true,
					-- Or use a function for more flexibility, e.g. to disable slow treesitter highlight for large files
					disable = function(lang, buf)
						local max_filesize = 100 * 1024 -- 100 KB
						local ok, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(buf))
						if ok and stats and stats.size > max_filesize then
							return true
						end
					end,
					additional_vim_regex_highlighting = false,
				},
				indent = {
					enable = true,
				},
			}
			end
	},
	{
		"nvim-treesitter/nvim-treesitter-context",
		lazy = false,
		cond = not vim.g.vscode,
		dependencies = { "nvim-treesitter/nvim-treesitter", },
	},
	{
		'nvim-treesitter/playground',
		lazy = false,
		cond = not vim.g.vscode,
		dependencies = { 'nvim-treesitter/nvim-treesitter' },
	},
	{
		"nvim-tree/nvim-web-devicons",
		lazy = true,
	},
	{
		"arkav/lualine-lsp-progress",
		lazy = true,
	},
	{
		"nvim-lualine/lualine.nvim",
		lazy = false,
		cond = not vim.g.vscode,
		dependencies = {
			"nvim-tree/nvim-web-devicons",
			"arkav/lualine-lsp-progress",
		},
		opts = {
			icons_enabled = true,
			theme = 'auto',
			component_separators = { left = '', right = ''},
			section_separators = { left = '', right = ''},
			disabled_filetypes = {
				statusline = {},
				winbar = {},
			},
			ignore_focus = {},
			always_divide_middle = true,
			globalstatus = false,
			refresh = {
				statusline = 1000,
				tabline = 1000,
				winbar = 1000,
			},
			sections = {
				lualine_a = {'mode'},
				lualine_b = {'branch', 'diff', 'diagnostics'},
				lualine_c = {{'filename', path = 1}, 'lsp_progress'},
				lualine_x = {'encoding', 'fileformat', 'filetype'},
				lualine_y = {'progress'},
				lualine_z = {'location'}
			},
			inactive_sections = {
				lualine_a = {},
				lualine_b = {},
				lualine_c = {'filename'},
				lualine_x = {'location'},
				lualine_y = {},
				lualine_z = {}
			},
			tabline = {},
			winbar = {},
			inactive_winbar = {},
			extensions = {}
		},
	},
	{
		"monaqa/dial.nvim",
		lazy = false,
		init = function()
			vim.keymap.set("n", "<C-a>", require("dial.map").inc_normal(), { noremap = true })
			vim.keymap.set("n", "<C-x>", require("dial.map").dec_normal(), { noremap = true })
			vim.keymap.set("n", "g<C-a>", require("dial.map").inc_gnormal(), { noremap = true })
			vim.keymap.set("n", "g<C-x>", require("dial.map").dec_gnormal(), { noremap = true })
			vim.keymap.set("v", "<C-a>", require("dial.map").inc_visual(), { noremap = true })
			vim.keymap.set("v", "<C-x>", require("dial.map").dec_visual(), { noremap = true })
			vim.keymap.set("v", "g<C-a>",require("dial.map").inc_gvisual(), { noremap = true })
			vim.keymap.set("v", "g<C-x>",require("dial.map").dec_gvisual(), { noremap = true })
		end,
	},
	{
		"mattn/vim-sonictemplate",
		lazy = false,
		init = function()
			vim.g.sonictemplate_vim_template_dir = CONFIG_HOME..'/nvim/templates'
		end,
	},
	{
		"vim-denops/denops.vim",
		lazy = true,
	},
	{
		"skanehira/denops-translate.vim",
		lazy = false,
		cond = not vim.g.vscode,
		dependencies = { "vim-denops/denops.vim", },
		config = function ()
			vim.keymap.set({'v', 'n'}, "<Leader><Leader>t", "<Cmd>Translate<CR>", { noremap = true, silent = true })
		end
	},
	{
		"neovim/nvim-lspconfig",
		cond = not vim.g.vscode,
		ft = {'rust', 'lua', 'typescript'},
		config = function()
			local lspconfig = require('lspconfig')

			local capabilities = vim.lsp.protocol.make_client_capabilities()
			capabilities.textDocument.completion.completionItem.snippetSupport = true
			lspconfig.rust_analyzer.setup {
				capabilities = capabilities,
				settings = {
					["rust-analyzer"] = {
						imports = {
							granularity = {
								group = "module",
							},
							prefix = "self",
						},
						cargo = {
							buildScripts = {
								enable = true,
							},
						},
						procMacro = {
							enable = true
						},
					},
				}
			}
			lspconfig.lua_ls.setup {
				settings = {
					Lua = {
						diagnostics = {
							globals = {'vim'},
						},
					},
				},
			}
			lspconfig.denols.setup {
				root_dir = lspconfig.util.root_pattern("deno.json", "deno.jsonc", "README.md"),
				init_options = {
					lint = true,
					unstable = true,
					suggest = {
						imports = {
							hosts = {
								["https://deno.land"] = true,
								["https://cdn.nest.land"] = true,
								["https://crux.land"] = true,
							},
						},
					},
				},
				single_file_support = true,
			}
			lspconfig.tsserver.setup {
				root_dir = lspconfig.util.root_pattern('package.json'),
				single_file_support = false,
			}

			-- Global mappings.
			-- See `:help vim.diagnostic.*` for documentation on any of the below functions
			vim.keymap.set('n', '<Leader>De', vim.diagnostic.open_float)
			vim.keymap.set('n', '<Leader>DN', vim.diagnostic.goto_prev)
			vim.keymap.set('n', '<Leader>Dn', vim.diagnostic.goto_next)
			vim.keymap.set('n', '<Leader>l', vim.diagnostic.setloclist)

			-- Use LspAttach autocommand to only map the following keys
			-- after the language server attaches to the current buffer
			vim.api.nvim_create_autocmd('LspAttach', {
				group = vim.api.nvim_create_augroup('UserLspConfig', {}),
				callback = function(ev)
					-- Enable completion triggered by <c-x><c-o>
					vim.bo[ev.buf].omnifunc = 'v:lua.vim.lsp.omnifunc'

					-- Buffer local mappings.
					-- See `:help vim.lsp.*` for documentation on any of the below functions
					local opts = { buffer = ev.buf }
					vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, opts)
					vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
					vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
					vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, opts)
					vim.keymap.set('n', '<C-k>', vim.lsp.buf.signature_help, opts)
					vim.keymap.set('n', '<Leader>wa', vim.lsp.buf.add_workspace_folder, opts)
					vim.keymap.set('n', '<Leader>wr', vim.lsp.buf.remove_workspace_folder, opts)
					vim.keymap.set('n', '<Leader>wl', function()
						print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
					end, opts)
					vim.keymap.set('n', '<space>D', vim.lsp.buf.type_definition, opts)
					vim.keymap.set('n', '<Leader>r', vim.lsp.buf.rename, opts)
					vim.keymap.set({ 'n', 'v' }, '<Leader>ca', vim.lsp.buf.code_action, opts)
					vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts)
					vim.keymap.set('n', '<Leader>f', function()
						vim.lsp.buf.format { async = true }
					end, opts)
				end,
			})
		end,
	},
	{
		"matsui54/denops-popup-preview.vim",
		lazy = true,
		dependencies = {
			"vim-denops/denops.vim",
		},
		config = function()
			vim.fn["popup_preview#enable"]()
		end,
	},
	{
		"matsui54/denops-signature_help",
		lazy = true,
		dependencies = {
			"vim-denops/denops.vim",
		},
		init = function()
			vim.g.signature_help_config = {
				contentsStyle = "full",
				viewStyle = "floating",
			}
		end,
		config = function()
			vim.fn["signature_help#enable"]()
		end,
	},
	{ "hrsh7th/vim-vsnip", lazy = true, },
	{
		"uga-rosa/ddc-source-vsnip",
		lazy = true,
		dependencies =
		{
			"vim-denops/denops.vim",
			"hrsh7th/vim-vsnip",
		},
	},
	{ "tani/ddc-fuzzy", lazy = true, },
	{ "Shougo/pum.vim", lazy = true, },
	{ "Shougo/ddc-ui-pum", lazy = true, },
	{ "Shougo/ddc-source-around", lazy = true, },
	{ "Shougo/ddc-sorter_rank", lazy = true, },
	{ "Shougo/ddc-source-nvim-lsp", lazy = true, },
	{ "Shougo/ddc-converter_remove_overlap", lazy = true, },
	{
		"vim-skk/skkeleton",
		lazy = false,
		dependencies = {
			"vim-denops/denops.vim",
		},
		event = { 'InsertEnter' },
		config = function()
			vim.api.nvim_create_autocmd({ 'User' }, {
				pattern = { 'skkeleton-initialize-pre' },
				callback = function()
					vim.fn["skkeleton#config"]({
						globalJisyo = '~/.skk/SKK-JISYO.L',
						eggLikeNewline = true,
					})
				end,
			})
			vim.api.nvim_create_autocmd({ 'User' }, {
				pattern = { 'DenopsPluginPost:skkeleton' },
				callback = function()
					vim.fn["skkeleton#initialize"]()
				end,
			})
			vim.keymap.set({'i', 'c', 't'}, '<C-j>', [[<Plug>(skkeleton-toggle)]], { noremap = false })
		end,
		init = function ()
			local function skkeleton_enable_pre()
				vim.g["prev_buffer_config"] = vim.fn["ddc#custom#get_buffer"]()
				vim.fn["ddc#custom#patch_buffer"]({
					sources = { "skkeleton" },
					sourceOptions = {
						skkeleton = {
							mark = "skk",
							matchers = { "skkeleton" },
							sorters = {},
							minAutoCompleteLength = 2,
						},
					},
				})
			end

			local function skkeleton_disable_pre()
				vim.fn["ddc#custom#set_buffer"](vim.g["prev_buffer_config"])
			end

		end
	},
	{
		"Shougo/ddc.vim",
		lazy = false,
		cond = not vim.g.vscode,
		dependencies = {
			"hrsh7th/vim-vsnip",
			"uga-rosa/ddc-source-vsnip",
			"vim-denops/denops.vim",
			"matsui54/denops-popup-preview.vim",
			"matsui54/denops-signature_help",
			"tani/ddc-fuzzy",
			"Shougo/pum.vim",
			"Shougo/ddc-ui-pum",
			"Shougo/ddc-source-around",
			"Shougo/ddc-sorter_rank",
			"Shougo/ddc-source-nvim-lsp",
			"Shougo/ddc-converter_remove_overlap",
			"vim-skk/skkeleton",
		},
		config = function()
			vim.fn["ddc#custom#patch_global"]({
				ui = 'pum',
				autoCompleteEvents = {'InsertEnter', 'TextChangedI', 'TextChangedP', 'CmdlineChanged', 'CmdlineEnter', 'TextChangedT'},
				sources = {
					'nvim-lsp',
					'skkeleton',
					'around',
				},
				backspaceCompletion = true,
				sourceOptions = {
					_ = {
						matchers = {'matcher_fuzzy'},
						sorters = {'sorter_fuzzy', 'sorter_rank'},
						converters = {'converter_remove_overlap', 'converter_fuzzy'},
						minAutoCompleteLength = 3,
					},
					["nvim-lsp"] = {
						mark = '[LSP]',
						forceCompletionPattern = {[['\.\w*|:\w*|->\w*']]},
						minAutoCompleteLength = 1,
					},
					skkeleton = {
						mark = '[skkeleton]',
						matchers = {'skkeleton'},
						sorters = {},
						minAutoCompleteLength = 2,
					},
					around = { mark = '[around]' },
				},
				sourceParams = {
					["nvim-lsp"] = {
						snippetEngine = vim.fn["denops#callback#register"](function(body) vim.fn["vsnip#anonymous"](body) end),
						enableResolveItem = true,
						enableAdditionalTextEdit = true,
					},
					around = { maxSize = 100 },
				},
			})
			vim.fn["ddc#custom#patch_filetype"]('markdown', 'sourceParams', {
				around = { maxSize = 50 }
			})
			vim.api.nvim_create_autocmd('InsertEnter', {
				callback = function(ev)
					local opt = { noremap = true }
					vim.keymap.set('i', '<C-n>', [[(pum#visible() ? '' : ddc#map#manual_complete()) . pum#map#select_relative(+1)]], { expr = true, noremap = false })
					vim.keymap.set('i', '<C-p>', [[(pum#visible() ? '' : ddc#map#manual_complete()) . pum#map#select_relative(-1)]], { expr = true, noremap = false })
					vim.keymap.set('i', '<C-y>', [[<Cmd>call pum#map#confirm()<CR>]], opt)
					vim.keymap.set('i', '<C-e>', [[<Cmd>call pum#map#cancel()<CR>]], opt)
					vim.keymap.set('i', '<PageDown>', [[<Cmd>call pum#map#insert_relative_page(+1)<CR>]], opt)
					vim.keymap.set('i', '<PageUp>', [[<Cmd>call pum#map#insert_relative_page(-1)<CR>]], opt)
					vim.keymap.set('i', '<CR>', [[pum#visible() ? pum#map#confirm() : '<CR>']], { expr = true, noremap = false })
					vim.keymap.set({'i', 's'}, '<C-l>', function() return vim.fn['vsnip#available'](1) == 1 and '<Plug>(vsnip-expand-or-jump)' or '<C-l>' end, { expr = true, noremap = false })
					vim.keymap.set({'i', 's'}, '<Tab>', function() return vim.fn['vsnip#jumpable'](1) == 1 and '<Plug>(vsnip-jump-next)' or '<Tab>' end, { expr = true, noremap = false })
					vim.keymap.set({'i', 's'}, '<S-Tab>', function() return vim.fn['vsnip#jumpable'](-1) == 1 and '<Plug>(vsnip-jump-prev)' or '<S-Tab>' end, { expr = true, noremap = false })
					vim.keymap.set({'n', 's'}, '<s>', [[<Plug>(vsnip-select-text)]], { expr = true, noremap = false })
					vim.keymap.set({'n', 's'}, '<S>', [[<Plug>(vsnip-cut-text)]], { expr = true, noremap = false })
				end,
			})
			vim.g.vsnip_filetypes = {}
			vim.fn["ddc#enable"]()
		end,
	},
	{ "Shougo/ddu-ui-ff", lazy = true, },
	{ "Shougo/ddu-ui-filer", lazy = true, },
	{ "Shougo/ddu-kind-file", lazy = true, },
	{ "Shougo/ddu-source-file_rec", lazy = true, },
	{ "Shougo/ddu-filter-matcher_substring", lazy = true, },
	{
		"Shougo/ddu-source-file",
		lazy = true,
		dependencies = {
			"Shougo/ddu-kind-file",
		}
	},
	{ "Shougo/ddu-source-buffer", lazy = true, },
	{ "Shougo/ddu-column-filename", lazy = true, },
	{
		"Shougo/ddu.vim",
		lazy = false,
		cond = not vim.g.vscode,
		dependencies = {
			"vim-denops/denops.vim",
			"Shougo/ddu.vim",
			"Shougo/ddu-ui-ff",
			"Shougo/ddu-ui-filer",
			"Shougo/ddu-kind-file",
			"Shougo/ddu-filter-matcher_substring",
			"Shougo/ddu-source-file",
			"Shougo/ddu-source-file_rec",
			"Shougo/ddu-source-buffer",
			"Shougo/ddu-column-filename",
		},
		config = function()
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
					}
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

			vim.api.nvim_create_autocmd('FileType', {
				pattern = { 'ddu-ff' },
				callback = function(ev)
					-- (ddu#ui#get_item()['__sourceName'] == 'buffer') ? 
					local opt = { noremap = true, silent = true, buffer = ev.buf }
					vim.keymap.set('n', '<CR>', [[<Cmd>call ddu#ui#do_action('itemAction')<CR>]], { noremap = true, silent = true })
					vim.keymap.set('n', 'S', [[<Cmd>call ddu#ui#do_action('itemAction', {'name': 'open', 'params': {'command': 'split'}})<CR>]], opt)
					vim.keymap.set('n', 'V', [[<Cmd>call ddu#ui#do_action('itemAction', {'name': 'open', 'params': {'command': 'vsplit'}})<CR>]], opt)
					vim.keymap.set('n', 'T', [[<Cmd>call ddu#ui#do_action('itemAction', {'name': 'open', 'params': {'command': 'tabedit'}})<CR>]], opt)
					vim.keymap.set('n', '<Esc>', [[<Cmd>call ddu#ui#do_action('quit')<CR>]], opt)
					vim.keymap.set('n', 'p', [[<Cmd>call ddu#ui#do_action('preview')<CR>]], opt)
					vim.keymap.set('n', 'd', [[<Cmd>call ddu#ui#do_action('itemAction', {'name': 'delete'})<CR>]], opt)
					vim.keymap.set('n', '<C-l>', [[<Cmd>call ddu#ui#do_action('itemAction', {'name': 'refresh'})<CR>]], opt)
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

			vim.api.nvim_create_autocmd({'TabEnter', 'CursorHold', 'FocusGained'}, {
				command = "call ddu#ui#filer#do_action('checkItems')"
			})
			vim.api.nvim_create_autocmd('FileType', {
				pattern = { 'ddu-filer' },
				callback = function(ev)
					local opt = { noremap = true, silent = true, buffer = ev.buf }
					local crAction = function ()
						if vim.fn['ddu#ui#get_item']()['action']['isDirectory'] then
							vim.fn["ddu#ui#filer#do_action"]('expandItem', {mode = 'toggle'})
						else
							vim.fn["ddu#ui#filer#do_action"]('itemAction', {name = 'open'})
						end
					end
					vim.keymap.set('n', '<CR>', crAction, opt)
					vim.keymap.set('n', 'o', [[<Cmd>call ddu#ui#filer#do_action('expandItem', {'mode': 'toggle'})<CR>]], opt)
					vim.keymap.set('n', '<Space>', [[<Cmd>call ddu#ui#filer#do_action('expandItem', {'mode': 'toggle'})<CR>]], opt)
					vim.keymap.set('n', '<Esc>', [[<Cmd>call ddu#ui#filer#do_action('quit')<CR>]], opt)
					vim.keymap.set('n', 'c', [[<Cmd>call ddu#ui#filer#do_action('itemAction', {'name': 'copy'})<CR>]], opt)
					vim.keymap.set('n', 'p', [[<Cmd>call ddu#ui#filer#do_action('itemAction', {'name': 'paste'})<CR>]], opt)
					vim.keymap.set('n', 'd', [[<Cmd>call ddu#ui#filer#do_action('itemAction', {'name': 'delete'})<CR>]], opt)
					vim.keymap.set('n', 'r', [[<Cmd>call ddu#ui#filer#do_action('itemAction', {'name': 'rename'})<CR>]], opt)
					vim.keymap.set('n', 'mv', [[<Cmd>call ddu#ui#filer#do_action('itemAction', {'name': 'move'})<CR>]], opt)
					vim.keymap.set('n', 't', [[<Cmd>call ddu#ui#filer#do_action('itemAction', {'name': 'newFile'})<CR>]], opt)
					vim.keymap.set('n', 'mk', [[<Cmd>call ddu#ui#filer#do_action('itemAction', {'name': 'newDirectory'})<CR>]], opt)
					vim.keymap.set('n', 'yy', [[<Cmd>call ddu#ui#filer#do_action('itemAction', {'name': 'yank'})<CR>]], opt)
					vim.keymap.set('n', 'S', [[<Cmd>call ddu#ui#filer#do_action('itemAction', {'name': 'open', 'params': {'command': 'split'}})<CR>]], opt)
					vim.keymap.set('n', 'V', [[<Cmd>call ddu#ui#filer#do_action('itemAction', {'name': 'open', 'params': {'command': 'vsplit'}})<CR>]], opt)
					vim.keymap.set('n', 'T', [[<Cmd>call ddu#ui#filer#do_action('itemAction', {'name': 'open', 'params': {'command': 'tabedit'}})<CR>]], opt)
				end,
			})
		end,
		init = function()
			vim.keymap.set('n', '<Leader>df', [[<Cmd>call ddu#start({ 'name': 'filer', 'searchPath': expand('%:p'), })<CR>]], { noremap = true, silent = true })
			vim.keymap.set('n', '<Leader>dF', [[<Cmd>call ddu#start(#{ sources: [#{ name: 'file_rec' }] })<CR>]], { noremap = true, silent = true })
			vim.keymap.set('n', '<Leader>db', [[<Cmd>call ddu#start(#{ sources: [#{ name: 'buffer' }] })<CR>]], { noremap = true, silent = true })
		end,
	},
	{
		'Shougo/deol.nvim',
		lazy = false,
		cond = not vim.g.vscode,
		init = function()
			vim.keymap.set('n', '<Leader>tt', [[<Cmd>tabnew<CR><Cmd>Deol<CR>]], { noremap = true, silent = true })
			vim.keymap.set('n', '<Leader>tc', [[<Cmd>Deol<CR>]], { noremap = true, silent = true }) -- current
			vim.keymap.set('n', '<Leader>tf', [[<Cmd>Deol -split=floating -winheight=30 -winwidth=160<CR>]], { noremap = true, silent = true })
			vim.keymap.set('n', '<Leader>tv', [[<Cmd>Deol -split=vertical<CR>]], { noremap = true, silent = true })
			vim.keymap.set('n', '<Leader>tr', [[<Cmd>Deol -split=farright<CR>]], { noremap = true, silent = true })
			vim.keymap.set('n', '<Leader>tl', [[<Cmd>Deol -split=farleft<CR>]], { noremap = true, silent = true })
		end
	},
}

---------------------------------------------------
-- install lazy
---------------------------------------------------
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable", -- latest stable release
		lazypath,
	})
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup(plugins)
