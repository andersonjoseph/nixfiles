return {
  "NickvanDyke/opencode.nvim",
  dependencies = {
    -- Recommended for `ask()` and `select()`.
    -- Required for `snacks` provider.
    ---@module 'snacks' <- Loads `snacks.nvim` types for configuration intellisense.
    { "folke/snacks.nvim", opts = { input = {}, picker = {}, terminal = {} } },
  },
  config = function()
    ---@type opencode.Opts

    -- Required for `opts.events.reload`.
    vim.o.autoread = true

    -- Recommended/example keymaps.
    vim.keymap.set("n", "<C-p>", function() require("opencode").ask("@buffer: ", { submit = true }) end, { desc = "Ask opencode…" })
    vim.keymap.set("v", "<C-p>", function() require("opencode").ask("@this: ", { submit = true }) end, { desc = "Ask opencode…" })

    vim.keymap.set({ "n", "x" }, "<C-.>", function() require("opencode").select() end,                          { desc = "Execute opencode action…" })
  end,
}
