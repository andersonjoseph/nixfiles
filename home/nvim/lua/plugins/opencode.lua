return {
  "NickvanDyke/opencode.nvim",
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
