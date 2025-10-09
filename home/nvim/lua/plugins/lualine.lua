return {
  'nvim-lualine/lualine.nvim',
  config = function()
    local kanagawa_paper = require("lualine.themes.kanagawa-paper-ink")

    require('lualine').setup {
      options = {
	theme = kanagawa_paper
      },
      sections = {
	lualine_a = {'mode'},
	lualine_b = {
	  {
	    function()
	      return "🎯 " .. require("grapple").name_or_index()
	    end,
	    cond = function()
	      return package.loaded["grapple"] and require("grapple").exists()
	    end
	  },
	  {
	    'filename',
	    path = 2,
	  }
	},
	lualine_c = {'diagnostics'},
	lualine_x = {'branch', "diagnostics"},
      }
    }
  end;
}
