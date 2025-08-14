return {
  {
    "dracula/vim",
    name = "dracula",
    lazy = true,
  },
  {
    "rebelot/kanagawa.nvim",
    lazy = true,
  },
  {
    "rose-pine/neovim",
    name = "rose-pine",
    lazy = true,
  },
  -- A clean, dark Neovim theme written in Lua, with support for lsp, treesitter and lots of plugins.
  -- Includes additional themes for Kitty, Alacritty, iTerm and Fish.
  {
    "folke/tokyonight.nvim",
    lazy = false,
    priority = 1000,
    opts = {
      style = "moon",
      on_highlights = function(hl, c)
        local Util = require("tokyonight.util")
        hl.TreesitterContext = {
          bg = Util.blend_bg(c.fg_gutter, 0.4),
        }
      end,
    },
  },
}
