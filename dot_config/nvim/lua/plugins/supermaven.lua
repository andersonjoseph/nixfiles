return {
  "supermaven-inc/supermaven-nvim",
  config = function()
    require("supermaven-nvim").setup({})

    vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
      pattern = { "*/leetcode/*" },
      callback = function()
	local api = require("supermaven-nvim.api")
	
	-- turn off inline suggestions in this buffer
	api.toggle(false)
      end,
    })
  end,
}
