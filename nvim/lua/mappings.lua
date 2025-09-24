vim.keymap.set('n', '<CR>', ':noh<CR><CR>')
vim.keymap.set('n', '<leader>q', ':bn<CR>:bd#<CR>')
vim.keymap.set('n', '<c-s>', ':w<CR>')

vim.keymap.set('i', '<c-s>', '<Esc>:w<CR>')

vim.keymap.set('t', '<Esc>', '<C-\\><C-n>')

vim.keymap.set('n', '<leader>y', '"+y')
vim.keymap.set('v', '<leader>y', '"+y')

vim.keymap.set('n', '<leader>p', '"+p')

local function jumplist_motion(key)
  return function()
    local count = vim.v.count1
    if count > 5 then 
      vim.cmd("normal! m'")
    end
    vim.cmd("normal! " .. count .. key)
  end
end

vim.keymap.set('n', 'j', jumplist_motion('j'), { silent = true })
vim.keymap.set('n', 'k', jumplist_motion('k'), { silent = true })
