-- Plugin-independent key mapping settings.

vim.g.mapleader = ' '

-- open terminal
vim.keymap.set('n', '<Leader>tt', [[<Cmd>tabnew<CR><Cmd>terminal<CR>]], { noremap = true, silent = true })

-- terminal
vim.keymap.set('t', '<C-Q>', [[<C-\><C-n>]], { noremap = true, silent = true })
