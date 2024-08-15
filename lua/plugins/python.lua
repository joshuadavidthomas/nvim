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
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        taplo = {
          on_attach = function(client, bufnr)
            local filename = vim.api.nvim_buf_get_name(bufnr)
            -- disable auto-formatting for `pyproject.toml`
            -- we use pre-commit hooks specific to `pyproject.toml`
            -- for linting and formatting
            if string.match(filename, "pyproject.toml") then
              client.server_capabilities.documentFormattingProvider = false
            end
          end,
        },
      },
    },
  },
}
