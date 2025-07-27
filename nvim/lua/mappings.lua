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

  -- this launch an i3 window with Drill
vim.keymap.set("n", "<leader>D", function()
  local file = vim.fn.expand("%:p")
  local line = vim.fn.line(".")
  local drill_cmd = table.concat({
    "drill",
    "-c",
    "-f", file,
    "-b", file .. ":" .. line,
  }, " ")
  local env_drill = "devenv shell -- " .. drill_cmd
  local escaped = vim.fn.shellescape(env_drill)
  local cwd = vim.fn.expand("%:p:h")
  local alacritty_cmd = table.concat({
    "alacritty",
    "--class", "Drill",
    "--working-directory", cwd,
    "-e", "sh", "-c", escaped,
  }, " ")

  -- build a single i3-msg invocation that:
  --  1) execs our Alacritty command
  --  2) sets any [class="Drill"] window to floating
  local i3_cmds = table.concat({
    "exec " .. alacritty_cmd,
    '[class="Drill"] floating enable',
  }, "; ")

  vim.fn.jobstart({ "i3-msg", i3_cmds }, {
    detach = true,
  })
end, {
  desc = "Run drill in a floating Alacritty i3 window, inside devenv shell"
})
