local p = require("utils.path")

local notes_vault = p.platformdirs().home .. "/Documents/notes"

return {
  "obsidian-nvim/obsidian.nvim",
  version = "*", -- use latest release instead of latest commit
  ft = "markdown",
  dependencies = {
    "nvim-lua/plenary.nvim",
  },
  opts = {
    completion = {
      blink = true,
    },
    workspaces = {
      {
        name = "notes",
        path = notes_vault,
      },
    },
  },
}
