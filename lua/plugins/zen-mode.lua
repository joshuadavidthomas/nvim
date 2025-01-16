return {
  "folke/zen-mode.nvim",
  cmd = "ZenMode",
  dependencies = {
    "folke/twilight.nvim",
  },
  opts = {
    plugins = {
      wezterm = {
        enabled = true,
        font = "+4",
      },
    },
  },
  keys = { { "<leader>z", "<cmd>ZenMode<cr>", desc = "Zen Mode" } },
}
