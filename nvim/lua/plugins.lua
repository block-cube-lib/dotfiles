return {
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
		config = function()
			show_end_of_line = true
		end
	},
	{
		"nvim-treesitter/nvim-treesitter",
		lazy = false,
		config = {
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
		},
	},
	{
		"nvim-treesitter/nvim-treesitter-context",
		lazy = false,
		dependencies = { "nvim-treesitter/nvim-treesitter", },
	},
	{
		'nvim-treesitter/playground',
		lazy = false,
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
		dependencies = {
			"nvim-tree/nvim-web-devicons",
			"arkav/lualine-lsp-progress",
		},
		config = {
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
			}
		},
		sections = {
			lualine_a = {'mode'},
			lualine_b = {'branch', 'diff', 'diagnostics'},
			lualine_c = {'filename', 'lsp_progress'},
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
	{
		"vim-denops/denops.vim",
		lazy = true,
	},
	{
		"skanehira/denops-translate.vim",
		lazy = false,
		dependencies = { "vim-denops/denops.vim", },
	},
	{
		"monaqa/dial.nvim",
		lazy = false,
		init = function()
			vim.keymap.set("n", "<C-a>", require("dial.map").inc_normal(), {noremap = true})
			vim.keymap.set("n", "<C-x>", require("dial.map").dec_normal(), {noremap = true})
			vim.keymap.set("n", "g<C-a>", require("dial.map").inc_gnormal(), {noremap = true})
			vim.keymap.set("n", "g<C-x>", require("dial.map").dec_gnormal(), {noremap = true})
			vim.keymap.set("v", "<C-a>", require("dial.map").inc_visual(), {noremap = true})
			vim.keymap.set("v", "<C-x>", require("dial.map").dec_visual(), {noremap = true})
			vim.keymap.set("v", "g<C-a>",require("dial.map").inc_gvisual(), {noremap = true})
			vim.keymap.set("v", "g<C-x>",require("dial.map").dec_gvisual(), {noremap = true})
		end,
	},
	{
		"neovim/nvim-lspconfig",
		ft = {'rust', 'ts'},
		config = function()
			local lspconfig = require('lspconfig')

			local on_attack = function(client)
				require'completion'.on_attack(client)
			end

			lspconfig.rust_analyzer.setup {
				-- Server-specific settings. See `:help lspconfig-setup`
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
					}
				}
			}

			-- Global mappings.
			-- See `:help vim.diagnostic.*` for documentation on any of the below functions
			vim.keymap.set('n', 'ge', vim.diagnostic.open_float)
			vim.keymap.set('n', '[d', vim.diagnostic.goto_prev)
			vim.keymap.set('n', ']d', vim.diagnostic.goto_next)
			vim.keymap.set('n', '<space>q', vim.diagnostic.setloclist)

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
					vim.keymap.set('n', '<space>wa', vim.lsp.buf.add_workspace_folder, opts)
					vim.keymap.set('n', '<space>wr', vim.lsp.buf.remove_workspace_folder, opts)
					vim.keymap.set('n', '<space>wl', function()
						print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
					end, opts)
					vim.keymap.set('n', '<space>D', vim.lsp.buf.type_definition, opts)
					vim.keymap.set('n', '<space>rn', vim.lsp.buf.rename, opts)
					vim.keymap.set({ 'n', 'v' }, '<space>ca', vim.lsp.buf.code_action, opts)
					vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts)
					vim.keymap.set('n', '<space>f', function()
						vim.lsp.buf.format { async = true }
					end, opts)
				end,
			})
		end,
	},
	{ "Shougo/ddc-ui-native", lazy = true, },
	{ "Shougo/ddc-source-around", lazy = true, },
	{ "Shougo/ddc-matcher_head", lazy = true, },
	{ "Shougo/ddc-sorter_rank", lazy = true, },
	{ "Shougo/ddc-source-nvim-lsp", lazy = true, },
	{
		"Shougo/ddc.vim",
		lazy = false,
		dependencies = {
			"vim-denops/denops.vim",
			"Shougo/ddc-ui-native",
			"Shougo/ddc-source-around",
			"Shougo/ddc-matcher_head",
			"Shougo/ddc-sorter_rank",
			"Shougo/ddc-source-nvim-lsp",
		},
		config = function()
			vim.fn["ddc#custom#patch_global"]('ui', 'native')
			vim.fn["ddc#custom#patch_global"]('sources', {'around', 'nvim-lsp'})
			vim.fn["ddc#custom#patch_global"]('sourceOptions', {
				_ = {
					matchers = {'matcher_head'},
					sorters = {'sorter_rank'},
				}
			})
			vim.fn["ddc#custom#patch_global"]('sourceOptions', {
				around = { mark = '[around]' },
				["nvim-lsp"] = {
					mark = '[LSP]',
					forceCompletionPattern = {[['\.\w*|:\w*|->\w*']]},
					minAutoCompleteLength = 0,
				},
			})
			vim.fn["ddc#custom#patch_global"]('sourceParams', {
				around = { maxSize = 500 },
				-- nvim-lsp = { kindLabels = { Class = 'c' } }
			})
			vim.fn["ddc#custom#patch_filetype"]('markdown', 'sourceParams', {
				around = { maxSize = 100 }
			})
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
					vim.keymap.set('n', '<CR>', [[<Cmd>call ddu#ui#filer#do_action('itemAction', {'name': 'open'})<CR>]], opt)
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
}

