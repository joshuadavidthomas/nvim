return {
  "sindrets/diffview.nvim",
  cmd = {
    "DiffviewOpen",
    "DiffviewClose",
    "DiffviewToggleFiles",
    "DiffviewFocusFiles",
  },
  opts = {
    keymaps = {
      -- stylua: ignore
      file_panel = {
        { "n", "q", "<cmd>DiffviewClose<cr>", { desc = "Close the Diffview" } },
      },
      -- stylua: ignore
      view = {
        { "n", "q", "<cmd>DiffviewClose<cr>", { desc = "Close the Diffview" } },
      },
    },
  },
  keys = {
    { "<leader>gd", "<cmd>DiffviewOpen<cr>", desc = "Diff" },
    {
      "<leader>gD",
      function()
        local default_branch = require("utils.git").get_default_branch(vim.fn.getcwd())
        if default_branch then
          vim.cmd("DiffviewOpen " .. default_branch .. "..HEAD")
        else
          vim.notify("Could not determine default branch", vim.log.levels.WARN)
        end
      end,
      desc = "Diff (default branch)",
    },
  },
}
