return {
  {
    "stevearc/conform.nvim",
    dependencies = {
      {
        "williamboman/mason.nvim",
        opts = function(_, opts)
          vim.list_extend(opts.ensure_installed, {
            "ruff",
          })
        end,
      },
    },
    opts = {
      formatters_by_ft = {
        python = { "ruff_fix", "ruff_format" },
      },
    },
  },
}
