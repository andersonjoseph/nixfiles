return {
  "ibhagwan/fzf-lua",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  opts = {
    grep = {
      hidden = true
    },
  },
  keys={
    {"<leader>ff", "<cmd>FzfLua files <cr>", desc="find files in current working directory"},
    {"<leader>fg", "<cmd>FzfLua live_grep<cr>", desc="grep"},
    {"<leader>fb", "<cmd>FzfLua lgrep_curbuf<cr>", desc="find in buffer"},
    {"<leader>fm", "<cmd>FzfLua marks <cr>", desc="find marks"},
    {"<leader>f<leader>", "<cmd>FzfLua resume <cr>", desc="resume previous find"},
    {"<leader><leader>", "<cmd>FzfLua buffers <cr>", desc="find open buffers"},
    {"<leader>fr", "<cmd>FzfLua lsp_references <cr>", desc="find references"},
    {"<leader>fd", "<cmd>FzfLua lsp_workspace_diagnostics <cr>", desc="find diagnostics"},
  }
}
