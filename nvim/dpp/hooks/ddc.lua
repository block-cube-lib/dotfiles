-- lua_source {{{
vim.fn["ddc#custom#patch_global"]({
	ui = 'pum',
	autoCompleteEvents = { 'InsertEnter', 'TextChangedI', 'TextChangedP', 'CmdlineChanged', 'CmdlineEnter', 'TextChangedT' },
	sources = {
		'skkeleton',
		'copilot',
		'lsp',
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
vim.fn["ddc#enable_terminal_completion"]()
vim.fn["ddc#enable"]()
--- }}}
