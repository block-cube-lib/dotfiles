-- Plugin-independent key mapping settings.

vim.g.mapleader = ' '

-- terminal
vim.keymap.set('t', '<C-Q>', [[<C-\><C-n>]], { noremap = true, silent = true })
