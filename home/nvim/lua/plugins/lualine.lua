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
