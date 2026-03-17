local function read_api_key()
  local file = io.open(os.getenv("HOME") .. "/.local/share/opencode/auth.json", "r")
  if file then
    local content = file:read("*all")
    file:close()
    local json = vim.json.decode(content)
    return json["zai-coding-plan"].key or ""
  end
  return ""
end

return {
  "yetone/avante.nvim",
  -- if you want to build from source then do `make BUILD_FROM_SOURCE=true`
  -- ⚠️ must add this setting! ! !
  build = "make",
  event = "VeryLazy",
  version = false, -- Never set this value to "*"! Never!
  init = function()
    vim.env.AVANTE_ANTHROPIC_API_KEY = read_api_key()
  end,
  ---@module 'avante'
  ---@type avante.Config
  opts = {
    instructions_file = "avante.md",
    provider = "claude",
    mode = "agentic",
    behaviour = {
      auto_apply_diff_after_generation = false,
      auto_approve_tool_permissions = false,
    },
    providers = {
      claude = {
        endpoint = "https://api.z.ai/api/anthropic",
        model = "glm-4.7",
        api_key_name = "AVANTE_ANTHROPIC_API_KEY",
        timeout = 30000, -- Timeout in milliseconds
          extra_request_body = {
            temperature = 0.75,
            max_tokens = 20480,
          },
      },
    },
  },
  dependencies = {
    "nvim-lua/plenary.nvim",
    "MunifTanjim/nui.nvim",
    --- The below dependencies are optional,
    "ibhagwan/fzf-lua", -- for file_selector provider fzf
    {
      -- Make sure to set this up properly if you have lazy=true
      'MeanderingProgrammer/render-markdown.nvim',
      opts = {
        file_types = { "markdown", "Avante" },
      },
      ft = { "markdown", "Avante" },
    },
  },
}
