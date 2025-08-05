return {
  -- Neovim Lua plugin to extend and create `a`/`i` textobjects.
  {
    "echasnovski/mini.ai",
    event = "LazyFile",
    opts = {},
  },
  {
    "echasnovski/mini.comment",
    event = "LazyFile",
    dependencies = {
      "JoosepAlviste/nvim-ts-context-commentstring",
      opts = {
        enable_autocmd = false,
      },
    },
    opts = {
      options = {
        custom_commentstring = function()
          return require("ts_context_commentstring.internal").calculate_commentstring() or vim.bo.commentstring
        end,
      },
    },
  },
  {
    "echasnovski/mini.icons",
    event = "VeryLazy",
    opts = {},
  },
  -- Neovim Lua plugin with fast and feature-rich surround actions.
  {
    "echasnovski/mini.surround",
    event = "LazyFile",
    opts = {},
  },
}
