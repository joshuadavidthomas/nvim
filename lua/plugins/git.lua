return {
  {
    "pwntester/octo.nvim",
    cmd = "Octo",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-telescope/telescope.nvim",
      "nvim-tree/nvim-web-devicons",
    },
    config = true,
    keys = {
      { "<leader>gi", "<CMD>Octo issue list<CR>", desc = "list repo [i]ssues" },
    },
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
