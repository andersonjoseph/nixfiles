return {
  "cursortab/cursortab.nvim",
  lazy = false,
  build = "cd server && go build",
  config = function()
    require("cursortab").setup({
      provider = {
        type = "mercuryapi",
        api_key_env = "MERCURY_AI_TOKEN",
      },
      behavior = {
        disabled_in = { "comment", "string" },
        idle_completion_delay = 75,
        text_change_debounce = 75,
        cursor_prediction = {
          enabled = true,
          auto_advance = true,
          proximity_threshold = 2,
        },
      },
    })
  end,
}
