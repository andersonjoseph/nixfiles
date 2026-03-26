return {
  'milanglacier/minuet-ai.nvim',
  dependencies = { 'nvim-lua/plenary.nvim' },
  config = function()
    require('minuet').setup {
      provider = 'openai_compatible',
      provider_options = {
        openai_compatible = {
          model = 'GLM-4.5',
          end_point = 'https://api.z.ai/api/coding/paas/v4/chat/completions',
          api_key = 'ZHIPU_API_KEY',
          name = 'Z.ai',
          stream = true,
          optional = {
            max_tokens = 512,
            thinking = {
              type = 'disabled',
            },
          },
        },
      },
    }
  end,
}
