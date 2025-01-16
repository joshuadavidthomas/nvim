return {
  {
    "kaarmu/typst.vim",
    event = "LazyFile",
    ft = "typst",
  },
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      "mason.nvim",
      "williamboman/mason-lspconfig.nvim",
    },
    ---@class PluginLspOpts
    opts = {
      ---@type lspconfig.options
      servers = {
        tinymist = {
          --- todo: these configuration from lspconfig maybe broken
          single_file_support = true,
          root_dir = function()
            return vim.fn.getcwd()
          end,
          --- See [Tinymist Server Configuration](https://github.com/Myriad-Dreamin/tinymist/blob/main/Configuration.md) for references.
          settings = {},
        },
      },
    },
  },
}
