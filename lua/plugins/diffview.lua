return {
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
    {
      "<leader>gD",
      function()
        local git = require("utils.git")
        local default_branch = git.get_default_branch(vim.fn.getcwd())
        if default_branch then
          vim.cmd("DiffviewOpen " .. default_branch .. "..HEAD")
        else
          vim.notify("Could not determine default branch", vim.log.levels.WARN)
        end
      end,
      desc = "DiffView (against default branch)",
    },
  },
}
