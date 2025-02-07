-- Create key bindings that stick. WhichKey helps you remember your Neovim keymaps, by showing available keybindings in a popup as you type.
return {
  "folke/which-key.nvim",
  event = "VeryLazy",
  opts = {
    preset = "helix",
    spec = {
      {
        mode = { "n", "v" },
        { "<leader>c", group = "code" },
        { "<leader>g", group = "git" },
        {
          "<leader>n",
          group = "notes",
          icon = function()
            icons = require("utils.icons")
            return {
              icon = icons.misc.note,
            }
          end,
        },
        { "<leader>q", group = "quit/session" },
        { "<leader>u", group = "ui", icon = { icon = "󰙵 ", color = "cyan" } },
        {
          "<leader>w",
          group = "windows",
          proxy = "<c-w>",
          expand = function()
            return require("which-key.extras").expand.win()
          end,
        },
      },
    },
  },
  keys = {
    {
      "<leader>?",
      function()
        require("which-key").show({ global = false })
      end,
      desc = "Buffer Keymaps",
    },
  },
}
