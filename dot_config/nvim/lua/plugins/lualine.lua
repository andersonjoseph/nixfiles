return {
  'nvim-lualine/lualine.nvim',
  config = function()
    require('lualine').setup {
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
