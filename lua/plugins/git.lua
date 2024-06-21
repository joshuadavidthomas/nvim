return {
  { import = "lazyvim.plugins.extras.lang.git" },
  {
    "pwntester/octo.nvim",
    cmd = "Octo",
    event = { { event = "BufReadCmd", pattern = "octo://*" } },
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-telescope/telescope.nvim",
      "nvim-tree/nvim-web-devicons",
      {
        "folke/which-key.nvim",
        opts = {
          defaults = {
            ["<leader>gp"] = { name = "+pr" },
          },
        },
      },
    },
    init = function()
      vim.treesitter.language.register("markdown", "octo")
    end,
    opts = function(_, opts)
      vim.api.nvim_create_autocmd("ExitPre", {
        group = vim.api.nvim_create_augroup("octo_exit_pre", { clear = true }),
        callback = function(ev)
          local keep = { "octo" }
          for _, win in ipairs(vim.api.nvim_list_wins()) do
            local buf = vim.api.nvim_win_get_buf(win)
            if vim.tbl_contains(keep, vim.bo[buf].filetype) then
              vim.bo[buf].buftype = "" -- set buftype to empty to keep the window
            end
          end
        end,
      })

      return {
        default_merge_method = "squash",
        default_to_projects_v2 = true,
        enable_builtin = true,
        outdated_icon = "󰥕 ",
      }
    end,
    keys = function()
      return {
        { "<leader>gi", "<cmd>Octo issue search<cr>", desc = "search [i]ssues" },
        { "<leader>go", "<cmd>Octo<cr>", desc = "find [o]cto command" },
        { "<leader>gps", "<cmd>Octo pr search<cr>", desc = "[s]earch PRs" },
        { "<leader>gpm", "<cmd>Octo pr merge<cr>", desc = "[m]erge PR" },
        { "<leader>gpo", "<cmd>Octo pr<cr>", desc = "[o]pen PR" },
        { "<leader>gpr", "<cmd>Octo review start", desc = "start PR [r]eview" },
        { "<leader>gpR", "<cmd>Octo review submit<cr>", desc = "submit [R]eview" },
        { "<leader>a", "", desc = "+[a]assignee", ft = "octo" },
        { "<leader>c", "", desc = "+[c]omment/code", ft = "octo" },
        { "<leader>l", "", desc = "+[l]abel", ft = "octo" },
        { "<leader>i", "", desc = "+[i]ssue", ft = "octo" },
        { "<leader>r", "", desc = "+[r]eact", ft = "octo" },
        { "<leader>p", "", desc = "+[p]r", ft = "octo" },
        { "<leader>v", "", desc = "+re[v]iew", ft = "octo" },
        { "@", "@<C-x><C-o>", mode = "i", ft = "octo", silent = true },
        { "#", "#<C-x><C-o>", mode = "i", ft = "octo", silent = true },
      }
    end,
  },
  {
    "sindrets/diffview.nvim",
    cmd = {
      "DiffviewOpen",
      "DiffviewClose",
      "DiffviewToggleFiles",
      "DiffviewFocusFiles",
    },
    opts = {},
    keys = {
      { "<leader>gd", "<cmd>DiffviewOpen<cr>", desc = "DiffView" },
    },
  },
}
