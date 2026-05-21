return {
  {
    "stevearc/conform.nvim",
    ---@module "conform"
    ---@type conform.setupOpts
    opts = {
      formatters_by_ft = {
        go = { "goimports", "gofumpt" },
      },
    },
  },
  {
    "mason-org/mason.nvim",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, {
        "delve",
      })
    end,
  },
  {
    "nvim-neotest/neotest",
    ft = "go",
    dependencies = {
      "fredrikaverpil/neotest-golang",
    },
    opts = {
      adapters = {
        ["neotest-golang"] = {},
      },
    },
  },
}
