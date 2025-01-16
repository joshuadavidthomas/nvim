local p = require("utils.path")

local vim_opened_to_dir = vim.fn.argc() > 0 and vim.fn.isdirectory(vim.fn.argv()[1]) == 1

return {
  "stevearc/oil.nvim",
  lazy = not vim_opened_to_dir,
  dependencies = { "nvim-tree/nvim-web-devicons" },
  opts = {
    default_file_explorer = true,
    keymaps = {
      gs = {
        callback = function()
          local oil = require("oil")
          local prefills = { paths = oil.get_current_dir() }
          local grug_far = require("grug-far")
          if not grug_far.has_instance("explorer") then
            grug_far.open({
              instanceName = "explorer",
              prefills = prefills,
              staticTitle = "Find and Replace from Explorer",
            })
          else
            grug_far.open_instance("explorer")
            grug_far.update_instance_prefills("explorer", prefills, false)
          end
        end,
        desc = "Grep search in directory",
      },
    },
    view_options = {
      is_hidden_file = function(name, _)
        local current_dir = require("oil").get_current_dir()
        return p.is_hidden_file(name, current_dir)
      end,
    },
  },
  keys = {
    {
      "<leader>fo",
      function()
        require("oil").open()
      end,
      desc = "File browser (oil)",
    },
    {
      "-",
      function()
        require("oil").open()
      end,
      mode = "n",
      desc = "File browser (oil)",
    },
  },
}
