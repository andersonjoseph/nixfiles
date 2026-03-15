-- Helper function to read API key from opencode auth.json
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
  "olimorris/codecompanion.nvim",
  version = "^19.0.0",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-treesitter/nvim-treesitter",
  },
  keys = {
    { "<leader>ac", ":CodeCompanionChat #{buffer} ", desc = "Open CodeCompanion", mode = "n" },
    { "<leader>ac", ":CodeCompanionChat #{buffer} ", desc = "Open CodeCompanion", mode = "v" },
    { "<leader>ai", ":CodeCompanion #{buffer} replace ", desc = "CodeCompanion inline", mode = "v" },
  },
  opts = {
    interactions = {
      shared = {
	keymaps = {
	  accept_change = {
	    callback = "keymaps.accept_change",
	    description = "Accept change",
	    modes = { n = "ga" },
	    opts = { nowait = true, noremap = true },
	  },
	  reject_change = {
	    callback = "keymaps.reject_change",
	    description = "Reject change",
	    modes = { n = "gr" },
	    opts = { nowait = true, noremap = true },
	  },
	},
      },
      chat = {
	adapter = "glm",
      },
      inline = {
	adapter = "glm",
      },
    },
    adapters = {
      http = {
	glm = function()
	  return require("codecompanion.adapters").extend("openai_compatible", {
	    env = {
	      url = "https://api.z.ai/api/coding/paas/v4",
	      api_key = read_api_key(),
	      chat_url = "/chat/completions",
	    },
	    schema = {
	      model = {
		default = "glm-4.7",
	      },
	    },
	  })
	end,
      },
    },
  },
}
