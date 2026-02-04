return {
  "NickvanDyke/opencode.nvim",
  config = function()
    ---@type opencode.Opts
    vim.g.opencode_opts = {
      provider = {
	cmd = "jailed-opencode --port --agent plan",
      }
    }

    -- Required for `opts.events.reload`.
    vim.o.autoread = true

    -- Recommended/example keymaps.
    vim.keymap.set("n", "<C-p>", function() require("opencode").ask("@buffer: ", { submit = true }) end, { desc = "Ask opencode…" })
    vim.keymap.set("v", "<C-p>", function() require("opencode").ask("@this: ", { submit = true }) end, { desc = "Ask opencode…" })
    vim.keymap.set({ "n", "t" }, "<S-C-p>", function() require("opencode").toggle() end,                          { desc = "Toggle opencode" })

    vim.keymap.set({ "n", "x" }, "<C-.>", function() require("opencode").select() end,                          { desc = "Execute opencode action…" })

    vim.keymap.set("n", "<S-C-u>", function() require("opencode").command("session.half.page.up") end,   { desc = "Scroll opencode up" })
    vim.keymap.set("n", "<S-C-d>", function() require("opencode").command("session.half.page.down") end, { desc = "Scroll opencode down" })
  end,
}
