return {
  "mfussenegger/nvim-dap",

  dependencies = {
    "igorlfs/nvim-dap-view",
    "leoluz/nvim-dap-go",
  },

  config = function()
    local dap = require("dap")
    require("dap-go").setup()

    local dapView = require("dap-view")
    dapView.setup({
      windows = {
	terminal = {
	  hide = { "go" },
	},
      },
    })

    vim.keymap.set('n', '<Leader>db', function() dap.toggle_breakpoint() end)
    vim.keymap.set('n', '<Leader>dc', function() dap.continue() end)

    local function open_dap_view()
      dapView.open()
      dapView.jump_to_view("scopes")
    end

    dap.listeners.before.attach["dap-view-config"] = function()
      open_dap_view()
    end
    dap.listeners.before.launch["dap-view-config"] = function()
      open_dap_view()
    end
    dap.listeners.before.event_terminated["dap-view-config"] = function()
      open_dap_view()
    end
    dap.listeners.before.event_exited["dap-view-config"] = function()
      open_dap_view()
    end

    local function focus_dap_view()
      vim.defer_fn(function()
	vim.cmd.normal(vim.api.nvim_replace_termcodes('<C-w><C-w>', true, false, true))
      end, 10)
    end

    vim.api.nvim_create_autocmd({ "FileType" }, {
      pattern = { "dap-view", "dap-view-term" },
      callback = function(evt)
        local opts = { buffer = evt.buf }
        
        vim.keymap.set("n", "n", function()
          dap.step_over()
          focus_dap_view()
        end, opts)
        
        vim.keymap.set("n", "s", function()
          dap.step_into()
          focus_dap_view()
        end, opts)
        
        vim.keymap.set("n", "o", function()
          dap.step_out()
          focus_dap_view()
        end, opts)
        
        vim.keymap.set("n", "c", function()
          dap.continue()
          focus_dap_view()
        end, opts)
      end,
    })
  end,
}
