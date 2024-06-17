local p = require("josh.utils.path")

return {
  {
    "stevearc/oil.nvim",
    event = "VimEnter",
    opts = {
      default_file_explorer = true,
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
  -- {
  --   "nvim-telescope/telescope.nvim",
  --   keys = {
  --     {
  --       "<leader>fp",
  --       function()
  --         require("telescope.builtin").find_files({ cwd = require("lazy.core.config").options.root })
  --       end,
  --       desc = "Find Plugin File",
  --     },
  --     { "<leader>fr", LazyVim.pick.telescope("oldfiles", { cwd = vim.uv.cwd() }), desc = "Recent (cwd)" },
  --     { "<leader>fR", "<cmd>Telescope oldfiles<cr>", desc = "Recent" },
  --   },
  --   opts = {
  --     defaults = {
  --       layout_strategy = "horizontal",
  --       layout_config = { prompt_position = "top" },
  --       sorting_strategy = "ascending",
  --       winblend = 0,
  --     },
  --   },
  -- },
  {
    "folke/which-key.nvim",
    opts = function(_, opts)
      table.insert(opts.defaults, {
        ["<leader>a"] = { name = "+tags" },
        ["<leader>n"] = { name = "+notes" },
      })
    end,
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
