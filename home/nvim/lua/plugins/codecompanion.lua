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
  version = "^18.0.0",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-treesitter/nvim-treesitter",
  },
  keys = {
    { "<leader>gc", ":CodeCompanionChat #{buffer} ", desc = "Open CodeCompanion", mode = "n" },
    { "<leader>gc", ":CodeCompanionChat #{buffer} ", desc = "Open CodeCompanion", mode = "v" },
    { "<leader>gi", ":CodeCompanion #{buffer} replace ", desc = "CodeCompanion inline", mode = "v" },
  },
  opts = {
    interactions = {
      chat = {
	adapter = "glm",
	tools = {
	  opts = {
	    default_tools = {
	      "full_stack_dev",
	    },
	  },
	},
	keymaps = {
	  accept_change = {
	    modes = { n = "ga" },
	  },
	  reject_change = {
	    modes = { n = "gr" },
	  },
	},
      },
      inline = {
	adapter = "glm",
	keymaps = {
	  accept_change = {
	    modes = { n = "ga" },
	  },
	  reject_change = {
	    modes = { n = "gr" },
	  },
	},
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
		default = "glm-4.6",
	      },
	    },
	  })
	end,
      },
      acp = {
	opencode = function()
	  return require("codecompanion.adapters").extend("opencode", {
	    commands = {
	      default = {
		"opencode",
		"acp",
	      },
	    },
	  })
	end,
      },
    },
  },
}
