vim.lsp.enable("gopls")
vim.lsp.enable("typescript")
vim.lsp.enable("python")
vim.lsp.enable("json")
vim.lsp.enable("nix")

vim.api.nvim_create_autocmd('LspAttach', {
  callback = function(ev)
    local client = vim.lsp.get_client_by_id(ev.data.client_id)

    local map = function(keys, func, desc, mode)
      mode = mode or "n"
      vim.keymap.set(mode, keys, func, {
	buffer = ev.buf,
	desc = "LSP: " .. desc,
      })
    end

    map("<leader>rn", vim.lsp.buf.rename, "[R]e[n]ame")
    map("<leader>gd", vim.lsp.buf.definition, "[G]oto [D]efinition")
    map("<leader>gi", vim.lsp.buf.implementation, "[G]oto [I]implementation")
    map("<leader>pb", vim.lsp.buf.format, "[P]rettify [B]buffer")
    map("<leader>ca", vim.lsp.buf.code_action, "[C]ode [A]action")
    map("<leader>d", function() vim.diagnostic.open_float({ scope = "cursor" }) end, "[D]iagnostics")
  end,
})

vim.cmd("set completeopt+=noselect")

vim.o.winborder = 'rounded'

vim.diagnostic.config({
  virtual_lines = true,
  signs = true,
  update_in_insert = true,
  underline = true,
  severity_sort = true,
  float = {
    focusable = false,
    style = "minimal",
    border = "rounded",
    source = "always",
    header = "",
    prefix = "",
  },
})
