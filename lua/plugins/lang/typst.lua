return {
  {
    "kaarmu/typst.vim",
    event = "LazyFile",
    ft = "typst",
  },
  {
    "williamboman/mason.nvim",
    opts = function(_, opts)
      vim.list_extend(opts.ensure_installed, {
        "typst-lsp",
      })
    end,
  },
}
