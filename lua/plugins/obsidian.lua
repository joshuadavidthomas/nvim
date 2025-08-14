return {
  "obsidian-nvim/obsidian.nvim",
  version = "*", -- use latest release instead of latest commit
  ft = "markdown",
  dependencies = {
    "nvim-lua/plenary.nvim",
  },
  opts = {
    legacy_commands = false, -- use new-style commands (e.g. :Obsidian backlinks)
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
