return {
  -- Detect tabstop and shiftwidth automatically
  "tpope/vim-sleuth",
  -- measure startuptime
  {
    "dstein64/vim-startuptime",
    cmd = "StartupTime",
    config = function()
      vim.g.startuptime_tries = 10
    end,
  },
  -- Session management. This saves your session in the background,
  -- keeping track of open buffers, window arrangement, and more.
  -- You can restore sessions when returning through the dashboard.
  {
    "folke/persistence.nvim",
    event = "BufReadPre",
    opts = { options = vim.opt.sessionoptions:get() },
    -- stylua: ignore
    keys = {
      { "<leader>qs", function() require("persistence").load() end, desc = "Restore [s]ession" },
      { "<leader>ql", function() require("persistence").load({ last = true }) end, desc = "Restore [l]ast Session" },
      { "<leader>qd", function() require("persistence").stop() end, desc = "[d]on't Save Current Session" },
    },
  },
}
