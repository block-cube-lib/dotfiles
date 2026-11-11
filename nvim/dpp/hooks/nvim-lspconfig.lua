-- lua_source {{{
-- Language servers, configured with the built-in
-- vim.lsp.config / vim.lsp.enable (Neovim 0.11+).
-- Server defaults come from nvim-lspconfig's lsp/*.lua.
-- (Neovim is kept at the latest version, so there is
-- deliberately no fallback to the legacy lspconfig setup.)

-- Prefer the capability set recommended by ddc-source-lsp (it
-- enables resolve support, item defaults, etc. for the ddc 'lsp'
-- source). That plugin loads on InsertEnter, so it may not be
-- require-able yet when this hook runs; fall back to the plain
-- defaults in that case.
local ok, ddc_source_lsp = pcall(require, 'ddc_source_lsp')
local capabilities
if ok then
	capabilities = ddc_source_lsp.make_client_capabilities()
else
	capabilities = vim.lsp.protocol.make_client_capabilities()
	capabilities.textDocument.completion.completionItem.snippetSupport = true
end

-- Global mappings.
-- See `:help vim.diagnostic.*` for documentation on any of the below functions
vim.keymap.set('n', '<Leader>De', vim.diagnostic.open_float)
vim.keymap.set('n', '<Leader>DN', function()
	vim.diagnostic.jump({ count = -1, float = true })
end)
vim.keymap.set('n', '<Leader>Dn', function()
	vim.diagnostic.jump({ count = 1, float = true })
end)
vim.keymap.set('n', '<Leader>l', vim.diagnostic.setloclist)

-- Use LspAttach autocommand to only map the following keys
-- after the language server attaches to the current buffer.
-- Registered before vim.lsp.enable so no attach is missed.
vim.api.nvim_create_autocmd('LspAttach', {
	group = vim.api.nvim_create_augroup('UserLspConfig', {}),
	callback = function(ev)
		-- Enable completion triggered by <c-x><c-o>
		vim.bo[ev.buf].omnifunc = 'v:lua.vim.lsp.omnifunc'

		-- Enable inlay hints for this buffer. Safe to call
		-- unconditionally: Neovim only queries supporting clients,
		-- including servers that register the capability later.
		if vim.lsp.inlay_hint then
			pcall(vim.lsp.inlay_hint.enable, true, { bufnr = ev.buf })
		end

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
			vim.lsp.buf.format({ timeout_ms = 2000 })
		end, opts)
	end,
})

-- Server setup.
vim.lsp.config('*', {
	capabilities = capabilities,
})

vim.lsp.config('rust_analyzer', {
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
	},
})

vim.lsp.config('lua_ls', {
	settings = {
		Lua = {
			diagnostics = {
				globals = { 'vim' },
			},
		},
	},
})

-- denols only inside Deno projects (deno.json / deno.jsonc).
vim.lsp.config('denols', {
	init_options = {
		lint = true,
		unstable = true,
		suggest = {
			imports = {
				hosts = {
					["https://deno.land"] = true,
					["https://cdn.nest.land"] = true,
					["https://crux.land"] = true,
					["https://jsr.io"] = true,
				},
			},
		},
	},
	root_dir = function(bufnr, on_dir)
		local root = vim.fs.root(bufnr, { 'deno.json', 'deno.jsonc' })
		if root then
			on_dir(root)
		end
	end,
})

-- ts_ls only inside Node projects, and never where Deno rules.
vim.lsp.config('ts_ls', {
	root_dir = function(bufnr, on_dir)
		if vim.fs.root(bufnr, { 'deno.json', 'deno.jsonc' }) then
			return
		end
		local root = vim.fs.root(bufnr, { 'package.json' })
		if root then
			on_dir(root)
		end
	end,
})

vim.lsp.enable({ 'csharp_ls', 'rust_analyzer', 'lua_ls', 'denols', 'ts_ls' })
-- }}}
