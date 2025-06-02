return {
  "otavioschwanck/arrow.nvim",
  dependencies = {
    { "nvim-tree/nvim-web-devicons" },
  },
  opts = {
    show_icons = true,
    leader_key = 'm',
    hide_handbook = true,
    mappings = {
      toggle = "a",
      clear_all_items = "X",
    }
  }
}
