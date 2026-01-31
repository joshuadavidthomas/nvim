local SKIP_UPDATING_FRONTMATTER = {
  "AGENTS.md",
  "CHANGELOG.md",
  "CLAUDE.md",
  "CONTRIBUTING.md",
  "README.md",
}

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
    frontmatter = {
      enabled = function(path)
        return not vim.list_contains(SKIP_UPDATING_FRONTMATTER, tostring(path))
      end,
    },
    legacy_commands = false, -- use new-style commands (e.g. :Obsidian backlinks)
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
