return {
  "swaits/zellij-nav.nvim",
  lazy = true,
  event = "VeryLazy",
  keys = {
    { "<A-Left>", "<cmd>ZellijNavigateLeftTab<cr>",  { silent = true, desc = "navigate left or tab"  } },
    { "<A-Down>", "<cmd>ZellijNavigateDown<cr>",  { silent = true, desc = "navigate down"  } },
    { "<A-Up>", "<cmd>ZellijNavigateUp<cr>",    { silent = true, desc = "navigate up"    } },
    { "<A-Right>", "<cmd>ZellijNavigateRightTab<cr>", { silent = true, desc = "navigate right or tab" } },
  },
  opts = {},
}
