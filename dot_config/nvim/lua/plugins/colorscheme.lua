return {
  "ellisonleao/gruvbox.nvim",
  lazy = false,
  priority = 1000,
  opts = {
    contrast = "",
  },
  init = function()
      vim.o.background = "dark"
      vim.cmd.colorscheme("gruvbox")
    end,
}
