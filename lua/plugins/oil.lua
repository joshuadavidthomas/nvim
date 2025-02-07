-- Neovim file explorer: edit your filesystem like a buffer
return {
  "stevearc/oil.nvim",
  lazy = not require("utils.vim").opened_to_dir,
  dependencies = {
    "echasnovski/mini.icons",
  },
  ---@module 'oil'
  ---@type oil.SetupOpts
  opts = {
    default_file_explorer = true,
    view_options = {
      is_hidden_file = function(name, _)
        local current_dir = require("oil").get_current_dir()
        return require("utils.path").is_hidden_file(name, current_dir)
      end,
    },
  },
  -- stylua: ignore
  keys = {
    { '-', function() require('oil').open() end, mode = 'n', desc = 'File browser' },
  },
}
