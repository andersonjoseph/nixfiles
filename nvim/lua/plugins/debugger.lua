return {
  "mfussenegger/nvim-dap",
  dependencies = { 
    {
      "igorlfs/nvim-dap-view",
      opts = {
	windows = {
	  terminal = {
	    -- The actual names of the adapters to hide
	    hide = { "go" }
	  }
	},
	auto_toggle = true,
      },
    },
    "leoluz/nvim-dap-go" 
  },

  config = function()
    local dap = require("dap")
    local dapView = require("dap-view")

    require("dap-go").setup()

    vim.keymap.set('n', '<leader>db', dap.toggle_breakpoint, { noremap=true })
    vim.keymap.set('n', '<leader>do', dapView.open,          { noremap=true })

    vim.keymap.set('n', '<leader>ds', dap.continue, { noremap=true })
    vim.keymap.set('n', '<leader>dc', dap.terminate, { noremap=true })

    local function keep_cursor_in_view(action)
      return function()
        local view_win = vim.api.nvim_get_current_win()
        action()
        vim.defer_fn(function()
          if vim.api.nvim_get_current_win() ~= view_win then
            vim.api.nvim_set_current_win(view_win)
          end
        end, 90)
      end
    end

    vim.api.nvim_create_autocmd("FileType", {
      pattern = { "dap-view", "dap-view-term", "dap-repl" },
      callback = function(ev)
        local opts = { buffer = ev.buf, noremap=true }

        vim.keymap.set("n", "n", keep_cursor_in_view(dap.step_over),  opts)
        vim.keymap.set("n", "s", keep_cursor_in_view(dap.step_into),  opts)
        vim.keymap.set("n", "o", keep_cursor_in_view(dap.step_out),  opts)
        vim.keymap.set("n", "c", keep_cursor_in_view(dap.continue),   opts)
      end,
    })
  end,
}
