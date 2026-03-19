return {
  "nickjvandyke/opencode.nvim",
  version = "*", -- Latest stable release
  dependencies = {
    {
      -- `snacks.nvim` integration is recommended, but optional
      ---@module "snacks" <- Loads `snacks.nvim` types for configuration intellisense
      "folke/snacks.nvim",
      optional = true,
      opts = {
        input = {}, -- Enhances `ask()`
        picker = { -- Enhances `select()`
          actions = {
            opencode_send = function(...) return require("opencode").snacks_picker_send(...) end,
          },
          win = {
            input = {
              keys = {
                ["<a-a>"] = { "opencode_send", mode = { "n", "i" } },
              },
            },
          },
        },
      },
    },
  },
  config = function()
    -- Required for `opts.events.reload`.
    vim.o.autoread = true

    -- Recommended/example keymaps.
    vim.keymap.set("n", "<C-p>", function() require("opencode").ask("@buffer: ", { submit = true }) end, { desc = "Ask opencode…" })
    vim.keymap.set("v", "<C-p>", function() require("opencode").ask("@this: ", { submit = true }) end, { desc = "Ask opencode…" })

    vim.keymap.set({ "n", "x" }, "<C-.>", function() require("opencode").select() end,                          { desc = "Execute opencode action…" })
  end,
}
