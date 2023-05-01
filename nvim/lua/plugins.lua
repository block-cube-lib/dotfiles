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
		"gpanders/editorconfig.nvim",
		lazy = false,
	},
	{
		"vim-denops/denops.vim",
		lazy = true,
	},
	{
		"skanehira/denops-translate.vim",
		lazy = false,
		dependencies = {
			"vim-denops/denops.vim",
		},
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
			vim.keymap.set('n', '<space>e', vim.diagnostic.open_float)
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
			})
			vim.fn["ddc#custom#patch_global"]('sourceOptions', {
				["nvim-lsp"] = {
					mark = '[LSP]',
					forceCompletionPattern = {[['\.\w*|:\w*|->\w*']]},
					minAutoCompleteLength = 1,
					backspaceCompletion = true,
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
}

