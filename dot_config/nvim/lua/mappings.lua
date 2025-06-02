vim.keymap.set('n', '<CR>', ':noh<CR><CR>')
vim.keymap.set('n', '<leader>q', ':bn<CR>:bd#<CR>')
vim.keymap.set('n', '<c-s>', ':w<CR>')

vim.keymap.set('i', '<c-s>', '<Esc>:w<CR>')

vim.keymap.set('t', '<Esc>', '<C-\\><C-n>')

vim.keymap.set('n', '<leader>y', '"+y')
vim.keymap.set('v', '<leader>y', '"+y')

vim.keymap.set('n', '<leader>p', '"+p')
