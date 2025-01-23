return {
  { import = "lazyvim.plugins.extras.lang.git" },
  {
    "folke/snacks.nvim",
    -- stylua: ignore
    keys = {
      { "<leader>gb", function() Snacks.git.blame_line() end, desc = "Git Blame Line" },
      { "<leader>gB", function() Snacks.gitbrowse() end, desc = "Git Browse", mode = { "n", "v" } },
    },
  },
}
