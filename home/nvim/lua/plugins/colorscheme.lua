return {
  "webhooked/kanso.nvim",
  lazy = false,
  priority = 1000,
  init = function()
    vim.cmd.colorscheme("kanso-ink")
  end,
}
