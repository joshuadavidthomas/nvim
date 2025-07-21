-- Lightweight yet powerful formatter plugin for Neovim
return {
  {
    "stevearc/conform.nvim",
    dependencies = {
      "mason-org/mason.nvim",
    },
    event = "LazyFile",
    cmd = "ConformInfo",
    ---@module "conform"
    ---@type conform.setupOpts
    opts = {
      default_format_opts = {
        lsp_format = "fallback",
      },
      format_on_save = function(bufnr)
        local bufpath = vim.api.nvim_buf_get_name(bufnr)
        if require("utils.format").projects.is_disabled(bufpath) then
          return false
        end
        return {
          async = false,
          quiet = false,
          timeout_ms = 3000,
        }
      end,
      formatters_by_ft = {
        lua = { "stylua" },
        sh = { "shfmt" },
      },
      notify_on_error = false,
    },
    config = function(_, opts)
      require("conform").setup(opts)

      local mr = require("mason-registry")

      local formatter_to_mason = {
        -- Python
        ruff_fix = "ruff",
        ruff_format = "ruff",
      }

      local ensure_installed = {} ---@type string[]
      for _, formatters in pairs(opts.formatters_by_ft) do
        for _, formatter in ipairs(formatters) do
          -- If there's a mapping, use it, otherwise use the formatter name
          local package_name = formatter_to_mason[formatter] or formatter
          table.insert(ensure_installed, package_name)
        end
      end
      ensure_installed = require("utils").dedupe(ensure_installed)

      mr:on("package:install:success", function()
        vim.defer_fn(function()
          if opts.format_on_save then
            require("conform").format({
              bufnr = vim.api.nvim_get_current_buf(),
              timeout_ms = opts.format_on_save.timeout_ms,
            })
          end
        end, 100)
      end)

      mr.refresh(function()
        for _, tool in ipairs(ensure_installed) do
          local ok, p = pcall(mr.get_package, tool)
          if ok and p and not p:is_installed() then
            p:install()
          end
        end
      end)
    end,
  },
}
