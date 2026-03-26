return {
  'saghen/blink.cmp',
  dependencies = { 'rafamadriz/friendly-snippets' },
  version = '1.*',
  config = function()
    require('blink-cmp').setup {
      keymap = {
        preset = 'enter',
        ['<C-y>'] = { function(cmp) cmp.show { providers = { 'minuet' } } end },
      },
      sources = {
        default = { 'lsp', 'path', 'buffer', 'snippets' },
        providers = {
          minuet = {
            name = 'minuet',
            module = 'minuet.blink',
            async = true,
            timeout_ms = 3000,
            score_offset = 100,
          },
        },
      },
      completion = {
        documentation = { auto_show = true },
        trigger = { prefetch_on_insert = false },
      },
      appearance = { nerd_font_variant = 'mono' },
      fuzzy = { implementation = "prefer_rust_with_warning" },
      signature = { enabled = true },
    }
  end,
}
