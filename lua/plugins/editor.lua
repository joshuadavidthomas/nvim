local p = require("josh.utils.path")

local vim_opened_to_dir = vim.fn.argc() > 0 and vim.fn.isdirectory(vim.fn.argv()[1]) == 1

return {
  {
    "stevearc/oil.nvim",
    lazy = not vim_opened_to_dir,
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
    dependencies = { "nvim-tree/nvim-web-devicons" },
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
  },
  {
    "chrisgrieser/nvim-early-retirement",
    config = true,
    event = "VeryLazy",
  },
  {
    "cbochs/grapple.nvim",
    dependencies = {
      "folke/which-key.nvim",
    },
    init = function()
      local wk = require("which-key")
      wk.add({
        { "<leader>a", group = "+tags" },
      })
    end,
    opts = {
      scope = "git", -- also try out "git_branch"
    },
    event = "LazyFile",
    cmd = "Grapple",
    keys = {
      { "<leader>at", "<cmd>Grapple toggle<cr>", desc = "[t]oggle file tag" },
      { "<leader>al", "<cmd>Grapple toggle_tags<cr>", desc = "[l]ist all tags" },
      { "<leader>aL", "<cmd>Grapple toggle_scopes<cr>", desc = "[L]ist all scopes" },
      { "<leader>aj", "<cmd>Grapple cycle forward<cr>", desc = "[j] move forward in tag list" },
      { "<leader>ak", "<cmd>Grapple cycle backward<cr>", desc = "[k] move backward in tag list" },
      { "<leader>a1", "<cmd>Grapple select index=1<cr>", desc = "select tag [1]" },
      { "<leader>a2", "<cmd>Grapple select index=2<cr>", desc = "select tag [2]" },
      { "<leader>a3", "<cmd>Grapple select index=3<cr>", desc = "select tag [3]" },
      { "<leader>a4", "<cmd>Grapple select index=4<cr>", desc = "select tag [4]" },
    },
  },
  {
    "nvim-neo-tree/neo-tree.nvim",
    opts = {
      filesystem = {
        hijack_netrw_behavior = "disabled",
      },
    },
  },
}
