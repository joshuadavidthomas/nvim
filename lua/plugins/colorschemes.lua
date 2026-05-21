local colorscheme = require("utils.colorscheme")
local active_colorscheme = colorscheme.read()

local function is_active(colorscheme)
  return active_colorscheme == colorscheme
end

local function load_active(colorscheme, setup)
  if not is_active(colorscheme) then
    return nil
  end

  return function(_, opts)
    if setup then
      setup(opts)
    end
    vim.cmd.colorscheme(colorscheme)
  end
end

return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    lazy = not is_active("catppuccin"),
    priority = is_active("catppuccin") and 1000 or nil,
    opts = {
      flavour = "auto",
    },
    config = load_active("catppuccin", function(opts)
      require("catppuccin").setup(opts)
    end),
  },
  {
    "dracula/vim",
    name = "dracula",
    lazy = not is_active("dracula"),
    priority = is_active("dracula") and 1000 or nil,
    config = load_active("dracula"),
  },
  {
    "rebelot/kanagawa.nvim",
    lazy = not is_active("kanagawa"),
    priority = is_active("kanagawa") and 1000 or nil,
    config = load_active("kanagawa"),
  },
  {
    "rose-pine/neovim",
    name = "rose-pine",
    lazy = not is_active("rose-pine"),
    priority = is_active("rose-pine") and 1000 or nil,
    config = load_active("rose-pine"),
  },
  {
    "folke/tokyonight.nvim",
    lazy = not is_active("tokyonight"),
    priority = is_active("tokyonight") and 1000 or nil,
    opts = {
      style = "moon",
      transparent = true,
      on_highlights = function(hl, c)
        local Util = require("tokyonight.util")
        hl.TreesitterContext = {
          bg = Util.blend_bg(c.fg_gutter, 0.4),
        }
      end,
    },
    config = load_active("tokyonight", function(opts)
      require("tokyonight").setup(opts)
    end),
  },
}
