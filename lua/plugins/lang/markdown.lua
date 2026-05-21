return {
  {
    "stevearc/conform.nvim",
    ---@module "conform"
    ---@type conform.setupOpts
    opts = {
      formatters_by_ft = {
        mdx = { "prettier" },
      },
    },
  },
  {
    "echasnovski/mini.icons",
    opts = {
      extension = {
        mdx = { glyph = "󰽛", hl = "MiniIconsBlue" },
      },
      filetype = {
        mdx = { glyph = "󰽛", hl = "MiniIconsBlue" },
      },
    },
  },
}
