-- lua_source {{{
-- Language servers.
-- Neovim 0.11+: use the built-in vim.lsp.config / vim.lsp.enable
-- (server defaults come from nvim-lspconfig's lsp/*.lua).
-- Older Neovim: fall back to the legacy lspconfig setup.

local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities.textDocument.completion.completionItem.snippetSupport = true

local rust_analyzer_settings = {
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

local lua_ls_settings = {
	Lua = {
		diagnostics = {
			globals = { 'vim' },
		},
	},
}

local denols_init_options = {
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
}

-- Global mappings.
-- See `:help vim.diagnostic.*` for documentation on any of the below functions
local function diag_jump(count)
	return function()
		if vim.diagnostic.jump then
			vim.diagnostic.jump({ count = count, float = true })
		elseif count < 0 then
			vim.diagnostic.goto_prev()
		else
			vim.diagnostic.goto_next()
		end
	end
end
vim.keymap.set('n', '<Leader>De', vim.diagnostic.open_float)
vim.keymap.set('n', '<Leader>DN', diag_jump(-1))
vim.keymap.set('n', '<Leader>Dn', diag_jump(1))
vim.keymap.set('n', '<Leader>l', vim.diagnostic.setloclist)

-- Use LspAttach autocommand to only map the following keys
-- after the language server attaches to the current buffer
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

-- Server setup (registered after LspAttach so no attach is missed).
local servers = { 'csharp_ls', 'rust_analyzer', 'lua_ls', 'denols', 'ts_ls' }

if vim.lsp.config and vim.lsp.enable then
	vim.lsp.config('*', {
		capabilities = capabilities,
	})

	vim.lsp.config('rust_analyzer', {
		settings = rust_analyzer_settings,
	})

	vim.lsp.config('lua_ls', {
		settings = lua_ls_settings,
	})

	-- denols only inside Deno projects (deno.json / deno.jsonc).
	vim.lsp.config('denols', {
		init_options = denols_init_options,
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

	vim.lsp.enable(servers)
else
	local lspconfig = require('lspconfig')

	lspconfig.csharp_ls.setup {
		capabilities = capabilities,
	}
	lspconfig.rust_analyzer.setup {
		capabilities = capabilities,
		settings = rust_analyzer_settings,
	}
	lspconfig.lua_ls.setup {
		capabilities = capabilities,
		settings = lua_ls_settings,
	}
	lspconfig.denols.setup {
		root_dir = lspconfig.util.root_pattern("deno.json", "deno.jsonc"),
		capabilities = capabilities,
		init_options = denols_init_options,
		single_file_support = false,
	}
	lspconfig.ts_ls.setup {
		root_dir = function(fname)
			if lspconfig.util.root_pattern("deno.json", "deno.jsonc")(fname) then
				return nil
			end
			return lspconfig.util.root_pattern('package.json')(fname)
		end,
		single_file_support = false,
		capabilities = capabilities,
	}
end
-- }}}
