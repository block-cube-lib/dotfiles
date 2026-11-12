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
		["lsp"] = {
			mark = '[LSP]',
			forceCompletionPattern = [[\.\w*|:\w*|->\w*]],
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
		["lsp"] = {
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
	callback = function(_)
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
-- Chain completion (Rust paths): confirming a module from the
-- LSP source after a `::` (e.g. `env` in `std::|`) inserts
-- another `::` and reopens completion, so the module's members
-- are offered without typing `::` first. The edit is deferred
-- with vim.schedule so ddc-source-lsp's own PumCompleteDone
-- handling (textEdit / additionalTextEdits) settles first; all
-- guards are re-checked against the final buffer state.
local chain_group = vim.api.nvim_create_augroup('ddc_chain_completion', { clear = true })
vim.api.nvim_create_autocmd('User', {
	group = chain_group,
	pattern = 'PumCompleteDone',
	callback = function()
		local item = vim.g['pum#completed_item']
		if type(item) ~= 'table' then
			return
		end
		if item.__sourceName ~= 'lsp' or item.kind ~= 'Module' then
			return
		end
		if vim.bo.filetype ~= 'rust' then
			return
		end
		local word = item.word or ''
		if word == '' then
			return
		end
		vim.schedule(function()
			if vim.fn.mode() ~= 'i' then
				return
			end
			local cursor = vim.api.nvim_win_get_cursor(0)
			local row, col = cursor[1], cursor[2]
			local before = vim.api.nvim_get_current_line():sub(1, col)
			-- Chain only in path position: the cursor is right
			-- after the confirmed word, and the word itself is
			-- preceded by `::`.
			if before:sub(-#word) ~= word then
				return
			end
			if before:sub(-#word - 2, -#word - 1) ~= '::' then
				return
			end
			vim.api.nvim_buf_set_text(0, row - 1, col, row - 1, col, { '::' })
			vim.api.nvim_win_set_cursor(0, { row, col + 2 })
			vim.fn['ddc#map#manual_complete']()
		end)
	end,
})

vim.fn["ddc#enable_terminal_completion"]()
vim.fn["ddc#enable"]()
--- }}}
