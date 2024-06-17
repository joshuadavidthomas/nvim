return {
  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    opts = function(_, opts)
      local extensions = {
        "oil",
      }
      for _, extension in ipairs(extensions) do
        table.insert(opts.extensions, extension)
      end
    end,
  },
  "folke/twilight.nvim",
  {
    "folke/zen-mode.nvim",
    cmd = "ZenMode",
    opts = {
      plugins = {
        wezterm = {
          enabled = true,
          font = "+4",
        },
      },
    },
    keys = { { "<leader>z", "<cmd>ZenMode<cr>", desc = "Zen Mode" } },
  },
}
