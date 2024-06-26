---------------------------------------------------
-- plugins
---------------------------------------------------
return
{
	{
		"folke/tokyonight.nvim",
		lazy = false,
		priority = 1000,
		config = function()
			vim.cmd([[colorscheme tokyonight-night]])
		end,
	},
	{
		"lukas-reineke/indent-blankline.nvim",
		lazy = false,
		main = "ibl",
		cond = not vim.g.vscode,
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
			component_separators = { left = '', right = '' },
			section_separators = { left = '', right = '' },
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
				lualine_a = { 'mode' },
				lualine_b = { 'branch', 'diff', 'diagnostics' },
				lualine_c = { { 'filename', path = 1 }, 'lsp_progress' },
				lualine_x = { 'encoding', 'fileformat', 'filetype' },
				lualine_y = { 'progress' },
				lualine_z = { 'location' }
			},
			inactive_sections = {
				lualine_a = {},
				lualine_b = {},
				lualine_c = { 'filename' },
				lualine_x = { 'location' },
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
			vim.keymap.set("v", "g<C-a>", require("dial.map").inc_gvisual(), { noremap = true })
			vim.keymap.set("v", "g<C-x>", require("dial.map").dec_gvisual(), { noremap = true })
		end,
	},
	{
		"mattn/vim-sonictemplate",
		lazy = false,
		init = function()
			vim.g.sonictemplate_vim_template_dir = {
					CONFIG_HOME .. '/nvim/templates',
					os.getenv("HOME") .. '/nvim_templates',
				}
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
		config = function()
			vim.keymap.set({ 'v', 'n' }, "<Leader><Leader>t", "<Cmd>Translate<CR>", { noremap = true, silent = true })
		end
	},
	{
		"neovim/nvim-lspconfig",
		cond = not vim.g.vscode,
		ft = { 'cs', 'rust', 'lua', 'typescript' },
		config = function()
			local lspconfig = require('lspconfig')

			local capabilities = vim.lsp.protocol.make_client_capabilities()
			capabilities.textDocument.completion.completionItem.snippetSupport = true
			lspconfig.csharp_ls.setup {
			}
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
							globals = { 'vim' },
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
	{ "tani/ddc-fuzzy",    lazy = true, },
	{
		"Shougo/pum.vim",
		lazy = true,
		cond = not vim.g.vscode,
	},
	{
		"Shougo/ddc-ui-pum",
		lazy = true,
		cond = not vim.g.vscode,
	},
	{
		"Shougo/ddc-source-around",
		lazy = true,
		cond = not vim.g.vscode,
	},
	{
		"Shougo/ddc-sorter_rank",
		lazy = true,
		cond = not vim.g.vscode,
	},
	{
		"Shougo/ddc-source-nvim-lsp",
		lazy = true,
		cond = not vim.g.vscode,
	},
	{
		"Shougo/ddc-converter_remove_overlap",
		lazy = true,
		cond = not vim.g.vscode,
	},
	{
		"Exafunction/codeium.vim",
		lazy = true,
		cond = false,
		config = function()
			vim.g.codeium_disable_bindings = 1
		end
	},
	{
		"Shougo/ddc-source-codeium",
		lazy = true,
		cond = false,
		dependencies = {
			"Exafunction/codeium.vim",
		}
	},
	{
		"github/copilot.vim",
		lazy = true,
		cond = not vim.g.vscode,
		config = function()
			vim.g.copilot_no_maps = true
			vim.g.copilot_filetypes = {
				text = true,
			}
		end
	},
	{
		"Shougo/ddc-source-copilot",
		lazy = true,
		dependencies = {
			"github/copilot.vim",
		}
	},
	{
		"vim-skk/skkeleton",
		lazy = false,
		cond = not vim.g.vscode,
		dependencies = {
			"vim-denops/denops.vim",
		},
		event = { 'InsertEnter' },
		config = function()
			vim.api.nvim_create_autocmd({ 'User' }, {
				pattern = { 'skkeleton-initialize-pre' },
				callback = function()
					vim.fn["skkeleton#config"]({
						globalDictionaries = { '~/.skk/SKK-JISYO.L' },
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
			vim.keymap.set({ 'i', 'c', 't' }, '<C-j>', [[<Plug>(skkeleton-toggle)]], { noremap = false })
		end,
	},
	{
		"delphinus/skkeleton_indicator.nvim",
		lazy = false,
		dependencies = {
			"vim-skk/skkeleton",
		},
		config = function()
			require("skkeleton_indicator").setup()
		end
	},
	{
		"gamoutatsumi/dps-ghosttext.vim",
		lazy = false,
		cond = not vim.g.vscode,
		dependencies = {
			"vim-denops/denops.vim",
			"vim-skk/skkeleton",
		},
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
			"Shougo/ddc-source-lsp",
			"Shougo/ddc-converter_remove_overlap",
			--"Shougo/ddc-source-codeium",
			"Shougo/ddc-source-copilot",
			"vim-skk/skkeleton",
		},
		config = function()
			vim.fn["ddc#custom#patch_global"]({
				ui = 'pum',
				autoCompleteEvents = { 'InsertEnter', 'TextChangedI', 'TextChangedP', 'CmdlineChanged', 'CmdlineEnter',
					'TextChangedT' },
				sources = {
					'skkeleton',
					'copilot',
					'lsp',
					--'codeium',
					'around',
				},
				backspaceCompletion = true,
				sourceOptions = {
					_ = {
						matchers = { 'matcher_fuzzy' },
						sorters = { 'sorter_fuzzy', 'sorter_rank' },
						converters = { 'converter_remove_overlap', 'converter_fuzzy' },
						minAutoCompleteLength = 3,
					},
					["nvim-lsp"] = {
						mark = '[LSP]',
						forceCompletionPattern = { [['\.\w*|:\w*|->\w*']] },
						minAutoCompleteLength = 1,
					},
					skkeleton = {
						mark = '[skkeleton]',
						matchers = {},
						sorters = {},
						converters = {},
						isVolatile = true,
						minAutoCompleteLength = 1,
					},
					["input"] = {
						mark = '[input]',
						matchers = {},
						minAutoCompleteLength = 0,
						forceCompletionPattern = { [['\S/\S*|\.\w*']] },
						isVolatile = true,
					},
					--codeium = {
					--	mark = '[codeium]',
					--	matchers = {},
					--	minAutoCompleteLength = 0,
					--	timeout = 1000,
					--	isVolatile = true,
					--},
					copilot = {
						mark = '[copilot]',
						matchers = {},
						minAutoCompleteLength = 0,
						isVolatile = true,
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
					vim.keymap.set({ 'i' }, '<C-n>',
						[[(pum#visible() ? '' : ddc#map#manual_complete()) . pum#map#select_relative(+1)]],
						{ expr = true, noremap = false })
					vim.keymap.set({ 'i' }, '<C-p>',
						[[(pum#visible() ? '' : ddc#map#manual_complete()) . pum#map#select_relative(-1)]],
						{ expr = true, noremap = false })
					vim.keymap.set({ 'i' }, '<C-y>', [[<Cmd>call pum#map#confirm()<CR>]], opt)
					vim.keymap.set({ 'i' }, '<C-e>', [[<Cmd>call pum#map#cancel()<CR>]], opt)
					vim.keymap.set({ 'i' }, '<PageDown>', [[<Cmd>call pum#map#insert_relative_page(+1)<CR>]], opt)
					vim.keymap.set({ 'i' }, '<PageUp>', [[<Cmd>call pum#map#insert_relative_page(-1)<CR>]], opt)
					vim.keymap.set({ 'i' }, '<CR>',
						function()
							if vim.fn['pum#entered']() then
								return '<Cmd>call pum#map#confirm()<CR>' or '<CR>'
							else
								return
								'<CR>'
							end
						end, { expr = true, noremap = false })
					vim.keymap.set({ 'i' }, '<C-m>',
						function()
							if vim.fn['pum#visible']() then
								return '<Cmd>call ddc#map#manual_complete()<CR>'
							else
								return
								'<C-m>'
							end
						end, { expr = true, noremap = false })
					vim.keymap.set({ 'i', 's' }, '<C-l>',
						function() return vim.fn['vsnip#available'](1) == 1 and '<Plug>(vsnip-expand-or-jump)' or '<C-l>' end,
						{ expr = true, noremap = false })
					vim.keymap.set({ 'i', 's' }, '<Tab>',
						function() return vim.fn['vsnip#jumpable'](1) == 1 and '<Plug>(vsnip-jump-next)' or '<Tab>' end,
						{ expr = true, noremap = false })
					vim.keymap.set({ 'i', 's' }, '<S-Tab>',
						function() return vim.fn['vsnip#jumpable'](-1) == 1 and '<Plug>(vsnip-jump-prev)' or '<S-Tab>' end,
						{ expr = true, noremap = false })
					vim.keymap.set({ 'n', 's' }, '<s>', [[<Plug>(vsnip-select-text)]], { expr = true, noremap = false })
					vim.keymap.set({ 'n', 's' }, '<S>', [[<Plug>(vsnip-cut-text)]], { expr = true, noremap = false })
				end,
			})
			vim.g.vsnip_filetypes = {}
			vim.fn["ddc#enable_terminal_completion"]()
			vim.fn["ddc#enable"]()
		end,
	},
	{ "Shougo/ddu-ui-ff",                    lazy = true, },
	{ "Shougo/ddu-ui-filer",                 lazy = true, },
	{ "Shougo/ddu-kind-file",                lazy = true, },
	{ "Shougo/ddu-source-file_rec",          lazy = true, },
	{ "Shougo/ddu-filter-matcher_substring", lazy = true, },
	{
		"Shougo/ddu-source-file",
		lazy = true,
		dependencies = {
			"Shougo/ddu-kind-file",
		}
	},
	{ "Shougo/ddu-source-buffer",       lazy = true, },
	{ "Shougo/ddu-column-filename",     lazy = true, },
	{ "Shougo/ddu-filter-sorter_alpha", lazy = true, },
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
			"Shougo/ddu-filter-sorter_alpha",
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
						sorters = { 'sorter_alpha' },
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
							ignoredDirectories = { "target", ".git", ".vscode", },
						},
						kindOptions = {
							file = { defaultAction = 'open', }
						},
					},
				},
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
		end,
		init = function()
			-- vim.keymap.set('n', '<Leader>df', [[<Cmd>call ddu#start({ name: 'filer', searchPath: expand('%:p'), })<CR>]],
			--	{ noremap = true, silent = true })
			vim.keymap.set('n', '<Leader>df',
				function()
					local searchPath = string.format("\"%s\"", vim.fn["expand"]('%:p'))
					print(searchPath)
					vim.fn["ddu#start"]({
						name = 'filer',
						searchPath = searchPath,
					})
				end,
				{ noremap = true, silent = true })
			vim.keymap.set('n', '<Leader>dF', [[<Cmd>call ddu#start(#{ name: 'file_recursive' })<CR>]],
				{ noremap = true, silent = true })
			vim.keymap.set('n', '<Leader>db', [[<Cmd>call ddu#start(#{ sources: [#{ name: 'buffer' }] })<CR>]],
				{ noremap = true, silent = true })
		end,
	},
	{
		'Shougo/deol.nvim',
		lazy = false,
		cond = not vim.g.vscode,
		init = function()
			local deol_command = function(option)
				if option == nil then
					option = {}
				end
				if option['edit'] == nil then
					option['edit'] = true
				end
				option['edit_filetype'] = 'deol-edit'
				return function() vim.fn['deol#start'](option) end
			end
			local opt = { noremap = true, silent = true };
			-- vim.keymap.set('n', '<Leader>tt', [[<Cmd>tabnew<CR>]] .. deol_command(), opt)
			vim.keymap.set('n', '<Leader>tc', deol_command(), opt) -- current
			vim.keymap.set('n', '<Leader>tf',
				deol_command({ split = 'floating', edit = false, winheight = 30, winwidth = 160 }), opt)
			vim.keymap.set('n', '<Leader>tv', deol_command({ split = 'vertical' }), opt)
			vim.keymap.set('n', '<Leader>tr', deol_command({ split = 'farright' }), opt)
			vim.keymap.set('n', '<Leader>tl', deol_command({ split = 'farleft' }), opt)

			vim.g["deol#prompt_pattern"] = "❯ ";
			vim.g["deol#extra_options"] = { term_finish = 'close' }

			vim.api.nvim_create_autocmd('FileType', {
				pattern = { 'deol-edit' },
				callback = function(ev)
					vim.keymap.set('i', '<C-Q>', [[<Esc>]], { noremap = true, silent = true })
				end,
			})
		end
	},
	{
		'glacambre/firenvim',
		lazy = false,
		cond = vim.g.started_by_firenvim,
		config = function()
			vim.g.firenvim_font = 'Cica'
			vim.o.guifont = 'Cica:h22'
		end,
		build = function()
			vim.fn["firenvim#install"](0)
		end
	},
	{
		'lambdalisue/gin.vim',
		lazy = false,
		dependencies = {
			"vim-denops/denops.vim",
		},
		init = function()
			vim.keymap.set('n', '<Leader>gs', [[<Cmd>GinStatus<CR>]], { noremap = true, silent = true })
			vim.keymap.set('n', '<Leader>gS', [[<Cmd>GinStatus ++opener=split<CR>]], { noremap = true, silent = true })
			vim.keymap.set('n', '<Leader>gb', [[<Cmd>GinBranch ++opener=split<CR>]], { noremap = true, silent = true })
			vim.api.nvim_create_autocmd('FileType', {
				pattern = { 'gin-status' },
				callback = function(ev)
					local opt = { noremap = true, silent = true, buffer = ev.buf }
					vim.keymap.set('n', '<C-r>', [[<Cmd>GinStatus<CR>]], opt)
				end,
			})
		end
	},
}
