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
        path = function()
          return require("utils.path").platformdirs().home .. "/notes"
        end,
      },
    },
  },
}
