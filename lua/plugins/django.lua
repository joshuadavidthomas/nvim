return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      vim.list_extend(opts.ensure_installed, {
        "htmldjango",
      })
    end,
  },
  {
    "williamboman/mason.nvim",
    opts = function(_, opts)
      vim.list_extend(opts.ensure_installed, {
        "djlint",
      })
    end,
  },
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        htmldjango = { "djlint" },
      },
    },
  },
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        django_lsp = {},
      },
      setup = {
        django_lsp = function(_, opts)
          local configs = require("lspconfig.configs")
          local util = require("lspconfig.util")

          local root_files = {
            "manage.py",
            "pyproject.toml",
          }

          if not configs.django_lsp then
            configs.django_lsp = {
              default_config = {
                -- cmd = { "lsp-devtools", "agent", "--", "django-lsp" },
                cmd = vim.lsp.rpc.connect("127.0.0.1", 9000),
                filetypes = { "htmldjango" },
                root_dir = function(fname)
                  return util.root_pattern(unpack(root_files))(fname) or util.path.dirname(fname)
                end,
                name = "django_lsp",
                options = {
                  logfile = util.path.join(vim.fn.stdpath("cache"), "django-lsp.log"),
                },
              },
            }
          end
        end,
      },
    },
  },
}
